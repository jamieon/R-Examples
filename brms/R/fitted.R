fitted_response <- function(x, eta, data) {
  # comnpute fitted values on the response scale
  # Args:
  #   x: A brmsfit object
  #   eta: untransformed linear predictor
  #   data: data initially passed to Stan
  # Returns: 
  #   (usually) an S x N matrix containing samples of 
  #   the response distribution's mean 
  family <- family(x)
  ee <- extract_effects(x$formula, family = family, nonlinear = x$nonlinear)
  nresp <- length(ee$response)
  is_catordinal <- is.ordinal(family) || is.categorical(family)
  if (is.lognormal(family, nresp = nresp)) {
    family$family <- "lognormal"
    family$link <- "identity"
  }
  if (is.2PL(family)) {
    # the second part of eta is the log discriminability
    eta <- eta[, 1:data$N_trait] * exp(eta[, (data$N_trait + 1):data$N])
  }
  is_trunc <- !(is.null(data$lb) && is.null(data$ub))
  
  # compute (mean) fitted values
  if (family$family == "binomial") {
    if (length(data$max_obs) > 1) {
      trials <- matrix(rep(data$max_obs, nrow(eta)), 
                       nrow = nrow(eta), byrow = TRUE)
    } else {
      trials <- data$max_obs
    }
    eta <- ilink(eta, family$link) 
    if (!is_trunc) {
      # scale eta from [0,1] to [0,max_obs]
      eta <- eta * trials 
    }
  } else if (family$family == "lognormal") {
    sigma <- get_sigma(x, data = data, n = nrow(eta))
    if (!is_trunc) {
      # compute untruncated lognormal mean
      eta <- ilink(eta + sigma^2 / 2, family$link)  
    }
  } else if (family$family == "weibull") {
    shape <- get_shape(x, data = data)
    eta <- ilink(eta / shape, family$link)
    if (!is_trunc) {
      # compute untruncated weibull mean
      eta <- eta * gamma(1 + 1 / shape) 
    }
  } else if (is_catordinal) {
    eta <- fitted_catordinal(eta, max_obs = data$max_obs, family = family)
  } else if (is.hurdle(family)) {
    shape <- posterior_samples(x, "^shape$")$shape 
    eta <- fitted_hurdle(eta, shape = shape, N_trait = data$N_trait,
                         family = family)
  } else if (is.zero_inflated(family)) {
    eta <- fitted_zero_inflated(eta, N_trait = data$N_trait, family = family)
    if (family$family == "zero_inflated_binomial") {
      trials <- data$max_obs[1:ceiling(length(data$max_obs) / 2)]
      trials <- matrix(rep(trials, nrow(eta)), nrow = nrow(eta), 
                       byrow = TRUE)
      eta <- eta * trials
    }
  } else {
    # for any other distribution, ilink(eta) is already the mean fitted value
    eta <- ilink(eta, family$link)
  }
  # fitted values for truncated models
  if (is_trunc) {
    lb <- ifelse(is.null(data$lb), -Inf, data$lb)
    ub <- ifelse(is.null(data$ub), Inf, data$ub)
    fitted_trunc_fun <- try(get(paste0("fitted_trunc_", family$family), 
                                mode = "function"))
    if (is(fitted_trunc_fun, "try-error")) {
      stop(paste("fitted values on the respone scale not implemented",
                 "for truncated", family, "models"))
    } else {
      eta <- fitted_trunc_fun(x = x, mu = eta, lb = lb, ub = ub, data = data)
    }
  } 
  eta
}

fitted_catordinal <- function(eta, max_obs, family) {
  # compute fitted values for categorical and ordinal families
  ncat <- max(max_obs)
  # get probabilities of each category
  get_density <- function(n) {
    do.call(paste0("d", family$family), 
            list(1:ncat, eta = eta[, n, ], ncat = ncat, link = family$link))
  }
  aperm(abind(lapply(1:ncol(eta), get_density), along = 3), perm = c(1, 3, 2))
}

fitted_hurdle <- function(eta, shape, N_trait, family) {
  # Args:
  #   eta: untransformed linear predictor
  #   shape: shape parameter samples
  #   N_trait: Number of observations of the main response variable
  n_base <- 1:N_trait
  n_hu <- n_base + N_trait
  pre_mu <- ilink(eta[, n_base], family$link)
  # adjust pre_mu as it is no longer the mean of the truncated distributions
  if (family$family == "hurdle_poisson") {
    adjusted_mu <- pre_mu / (1 - exp(-pre_mu))
  } else if (family$family == "hurdle_negbinomial") {
    adjusted_mu <- pre_mu / (1 - (shape / (pre_mu + shape))^shape)
  } else {
    adjusted_mu <- pre_mu
  }
  # incorporate hurdle part
  pre_mu * (1 - ilink(eta[, n_hu], "logit")) 
}

fitted_zero_inflated <- function(eta, N_trait, family) {
  # Args:
  #   eta: untransformed linear predictor
  #   N_trait: Number of observations of the main response variable
  n_base <- 1:N_trait
  n_zi <- n_base + N_trait
  # incorporate zero-inflation part
  ilink(eta[, n_base], family$link) * (1 - ilink(eta[, n_zi], "logit")) 
}

#------------- helper functions for truncated models ----------------
# Args:
#   x: a brmsfit object
#   mu: (usually) samples of the untruncated mean parameter
#   lb: lower truncation bound
#   ub: upper truncation bound
#   data: data iniitally passed to Stan
#   ...: ignored arguments
# Returns:
#   samples of the truncated mean parameter
fitted_trunc_gaussian <- function(mu, lb, ub, x, data) {
  sigma <- get_sigma(x, data = data, method = "fitted", n = nrow(mu))
  zlb <- (lb - mu) / sigma
  zub <- (ub - mu) / sigma
  # truncated mean of standard normal; see Wikipedia
  trunc_zmean <- (dnorm(zlb) - dnorm(zub)) / (pnorm(zub) - pnorm(zlb))  
  mu + trunc_zmean * sigma  
}

fitted_trunc_student <- function(mu, lb, ub, x, data) {
  sigma <- get_sigma(x, data = data, method = "fitted", n = nrow(mu))
  nu <- posterior_samples(x, pars = "^nu$")$nu
  zlb <- (lb - mu) / sigma
  zub <- (ub - mu) / sigma
  # see Kim 2008: Moments of truncated Student-t distribution
  G1 <- gamma((nu - 1) / 2) * nu^(nu / 2) / 
    (2 * (pt(zub, df = nu) - pt(zlb, df = nu)) * gamma(nu / 2) * gamma(0.5))
  A <- (nu + zlb^2) ^ (-(nu - 1) / 2)
  B <- (nu + zub^2) ^ (-(nu - 1) / 2)
  trunc_zmean <- G1 * (A - B)
  mu + trunc_zmean * sigma 
}

fitted_trunc_lognormal <- function(mu, lb, ub, x, data) {
  # mu has to be on the linear scale
  sigma <- get_sigma(x, data = data, method = "fitted", n = nrow(mu))
  m1 <- exp(mu + sigma^2 / 2) * (pnorm((log(ub) - mu) / sigma - sigma) - 
                                   pnorm((log(lb) - mu) / sigma - sigma))
  m1 / (plnorm(ub, meanlog = mu, sdlog = sigma) - 
          plnorm(lb, meanlog = mu, sdlog = sigma))
}

fitted_trunc_gamma <- function(mu, lb, ub, x, ...) {
  shape <- posterior_samples(x, pars = "^shape$")$shape
  scale <- mu / shape
  # see Jawitz 2004: Moments of truncated continuous univariate distributions
  m1 <- scale / gamma(shape) * 
    (incgamma(ub / scale, 1 + shape) - incgamma(lb / scale, 1 + shape))
  m1 / (pgamma(ub, shape, scale = scale) - pgamma(lb, shape, scale = scale))
}

fitted_trunc_exponential <- function(mu, lb, ub, ...) {
  # see Jawitz 2004: Moments of truncated continuous univariate distributions
  # mu is already the scale parameter
  inv_mu <- 1 / mu
  m1 <- mu * (incgamma(ub / mu, 2) - incgamma(lb / mu, 2))
  m1 / (pexp(ub, rate = inv_mu) - pexp(lb, rate = inv_mu))
}

fitted_trunc_weibull <- function(mu, lb, ub, x, ...) {
  # see Jawitz 2004: Moments of truncated continuous univariate distributions
  # mu is already the scale parameter
  shape <- posterior_samples(x, pars = "^shape$")$shape
  a <- 1 + 1 / shape
  m1 <- mu * (incgamma((ub / mu)^shape, a) - incgamma((lb / mu)^shape, a))
  m1 / (pweibull(ub, shape, scale = mu) - pweibull(lb, shape, scale = mu))
}

fitted_trunc_binomial <- function(mu, lb, ub, data, ...) {
  lb <- max(lb, -1)
  ub <- min(ub, max(data$trials))
  trials <- data$trials
  if (length(trials) > 1) {
    trials <- matrix(rep(trials, nrow(mu)), ncol = data$N, byrow = TRUE)
  }
  args <- list(size = trials, prob = mu)
  message(paste("Computing fitted values for a truncated binomial model.",
                "This may take a while."))
  fitted_trunc_discrete(dist = "binom", args = args, lb = lb, ub = ub)
}

fitted_trunc_poisson <- function(mu, lb, ub, data, ...) {
  lb <- max(lb, -1)
  ub <- min(ub, 3 * max(data$Y))
  args <- list(lambda = mu)
  message(paste("Computing fitted values for a truncated poisson model.",
                "This may take a while."))
  fitted_trunc_discrete(dist = "pois", args = args, lb = lb, ub = ub)
}

fitted_trunc_negbinomial <- function(mu, lb, ub, x, data, ...) {
  lb <- max(lb, -1)
  ub <- min(ub, 3 * max(data$Y))
  shape <- posterior_samples(x, pars = "^shape$")$shape
  args <- list(mu = mu, size = shape)
  message(paste("Computing fitted values for a truncated negbinomial model.",
                "This may take a while."))
  fitted_trunc_discrete(dist = "nbinom", args = args, lb = lb, ub = ub)
}

fitted_trunc_geometric <- function(mu, lb, ub, data, ...) {
  lb <- max(lb, -1)
  ub <- min(ub, 3 * max(data$Y))
  args <- list(mu = mu, size = 1)
  message(paste("Computing fitted values for a truncated geometric model.",
                "This may take a while."))
  fitted_trunc_discrete(dist = "nbinom", args = args, lb = lb, ub = ub)
}

fitted_trunc_discrete <- function(dist, args, lb, ub) {
  pdf <- get(paste0("d", dist), mode = "function")
  cdf <- get(paste0("p", dist), mode = "function")
  get_mean_kernel <- function(x, args) {
    # just x * density(x)
    x * do.call(pdf, c(x, args))
  }
  if (any(is.infinite(c(lb, ub))))
    stop("lb and ub must be finite")
  # array of dimension S x N x length(lg:ub)
  mean_kernel <- lapply((lb + 1):ub, get_mean_kernel, args = args)
  mean_kernel <- do.call(abind, c(mean_kernel, along = 3))
  m1 <- apply(mean_kernel, MARGIN = 2, FUN = rowSums)
  m1 / (do.call(cdf, c(ub, args)) - do.call(cdf, c(lb, args)))
}