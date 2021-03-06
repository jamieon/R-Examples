gaussian.CARar <- function(formula, data=NULL, W, burnin, n.sample, thin=1,  prior.mean.beta=NULL, prior.var.beta=NULL, prior.nu2=NULL, prior.tau2=NULL, fix.rho.S=FALSE, rho.S=NULL, fix.rho.T=FALSE, rho.T=NULL, verbose=TRUE)
{
#### Check on the verbose option
    if(is.null(verbose)) verbose=TRUE     
    if(!is.logical(verbose)) stop("the verbose option is not logical.", call.=FALSE)
    
    if(verbose)
    {
        cat("Setting up the model\n")
        a<-proc.time()
    }else{}
    
    
    
    ##############################################
    #### Format the arguments and check for errors
    ##############################################
    #### Overall formula object
    frame <- try(suppressWarnings(model.frame(formula, data=data, na.action=na.pass)), silent=TRUE)
    if(class(frame)=="try-error") stop("the formula inputted contains an error, e.g the variables may be different lengths or the data object has not been specified.", call.=FALSE)
    
    
    #### Design matrix
    ## Create the matrix
    X <- try(suppressWarnings(model.matrix(object=attr(frame, "terms"), data=frame)), silent=TRUE)
    if(class(X)=="try-error") stop("the covariate matrix contains inappropriate values.", call.=FALSE)
    if(sum(is.na(X))>0) stop("the covariate matrix contains missing 'NA' values.", call.=FALSE)
    N.all <- nrow(X)
    p <- ncol(X)
    
    ## Check for linearly related columns
    cor.X <- suppressWarnings(cor(X))
    diag(cor.X) <- 0
    
    if(max(cor.X, na.rm=TRUE)==1) stop("the covariate matrix has two exactly linearly related columns.", call.=FALSE)
    if(min(cor.X, na.rm=TRUE)==-1) stop("the covariate matrix has two exactly linearly related columns.", call.=FALSE)
    
    if(p>1)
    {
        if(sort(apply(X, 2, sd))[2]==0) stop("the covariate matrix has two intercept terms.", call.=FALSE)
    }else
    {
    }
    
    ## Standardise the matrix
    X.standardised <- X
    X.sd <- apply(X, 2, sd)
    X.mean <- apply(X, 2, mean)
    X.indicator <- rep(NA, p)       # To determine which parameter estimates to transform back
    
    for(j in 1:p)
    {
        if(length(table(X[ ,j]))>2)
        {
            X.indicator[j] <- 1
            X.standardised[ ,j] <- (X[ ,j] - mean(X[ ,j])) / sd(X[ ,j])
        }else if(length(table(X[ ,j]))==1)
        {
            X.indicator[j] <- 2
        }else
        {
            X.indicator[j] <- 0
        }
    }
    
    
    #### Format and check the neighbourhood matrix W
    if(!is.matrix(W)) stop("W is not a matrix.", call.=FALSE)
    K <- nrow(W)
    if(ncol(W)!= K) stop("W has the wrong number of columns.", call.=FALSE)
    if(nrow(W)!= K) stop("W has the wrong number of rows.", call.=FALSE)
    if(floor(N.all/K)!=ceiling(N.all/K)) stop("The number of spatial areas is not a multiple of the number of data points.", call.=FALSE)
    N <- N.all / K
    if(sum(is.na(W))>0) stop("W has missing 'NA' values.", call.=FALSE)
    if(!is.numeric(W)) stop("W has non-numeric values.", call.=FALSE)
    if(min(W)<0) stop("W has negative elements.", call.=FALSE)
    if(sum(W!=t(W))>0) stop("W is not symmetric.", call.=FALSE)
    if(min(apply(W, 1, sum))==0) stop("W has some areas with no neighbours (one of the row sums equals zero).", call.=FALSE)    
    
    #### Response variable
    Y <- model.response(frame)
    which.miss <- as.numeric(!is.na(Y))
    which.miss.mat <- matrix(which.miss, nrow=K, ncol=N, byrow=FALSE)
    n.miss <- N.all - sum(which.miss)
    Y.miss <- Y
    Y.miss[which.miss==0] <- median(Y, na.rm=TRUE)    
    if(!is.numeric(Y)) stop("the response variable has non-numeric values.", call.=FALSE)
    X.short <- X.standardised[which.miss==1, ]    
    
    
#### Offset variable
offset <- try(model.offset(frame), silent=TRUE)
    if(class(offset)=="try-error")   stop("the offset is not numeric.", call.=FALSE)
    if(is.null(offset))  offset <- rep(0,N.all)
    if(sum(is.na(offset))>0) stop("the offset has missing 'NA' values.", call.=FALSE)
    if(!is.numeric(offset)) stop("the offset variable has non-numeric values.", call.=FALSE)
    
    


    
#### Specify the initial parameter values
mod.glm <- glm(Y~X.standardised-1, offset=offset)
beta.mean <- mod.glm$coefficients
beta.sd <- sqrt(diag(summary(mod.glm)$cov.scaled))
beta <- rnorm(n=length(beta.mean), mean=beta.mean, sd=beta.sd)

res.temp <- Y - X.standardised %*% beta - offset
res.sd <- sd(res.temp, na.rm=TRUE)/5
phi <- rnorm(n=N.all, mean=0, sd = res.sd)
tau2 <- var(phi)/10
if(fix.rho.S)
{
    rho <- rho.S
}else
{
    rho <- runif(1)       
}

if(fix.rho.T)
{
    gamma <- rho.T
}else
{
    gamma <- runif(1)       
}   



#### Check and specify the priors
## Put in default priors
    if(is.null(prior.mean.beta)) prior.mean.beta <- rep(0, p)
    if(is.null(prior.var.beta)) prior.var.beta <- rep(1000, p)
    if(is.null(prior.tau2)) prior.tau2 <- c(0.001, 0.001)
    if(is.null(prior.nu2)) prior.nu2 <- c(0.001, 0.001)

    if(length(prior.mean.beta)!=p) stop("the vector of prior means for beta is the wrong length.", call.=FALSE)    
    if(!is.numeric(prior.mean.beta)) stop("the vector of prior means for beta is not numeric.", call.=FALSE)    
    if(sum(is.na(prior.mean.beta))!=0) stop("the vector of prior means for beta has missing values.", call.=FALSE)       
    
    if(length(prior.var.beta)!=p) stop("the vector of prior variances for beta is the wrong length.", call.=FALSE)    
    if(!is.numeric(prior.var.beta)) stop("the vector of prior variances for beta is not numeric.", call.=FALSE)    
    if(sum(is.na(prior.var.beta))!=0) stop("the vector of prior variances for beta has missing values.", call.=FALSE)    
    if(min(prior.var.beta) <=0) stop("the vector of prior variances has elements less than zero", call.=FALSE)
    
    if(length(prior.tau2)!=2) stop("the prior value for tau2 is the wrong length.", call.=FALSE)    
    if(!is.numeric(prior.tau2)) stop("the prior value for tau2 is not numeric.", call.=FALSE)    
    if(sum(is.na(prior.tau2))!=0) stop("the prior value for tau2 has missing values.", call.=FALSE)   
    
    if(length(prior.nu2)!=2) stop("the prior value for nu2 is the wrong length.", call.=FALSE)    
    if(!is.numeric(prior.nu2)) stop("the prior value for nu2 is not numeric.", call.=FALSE)    
    if(sum(is.na(prior.nu2))!=0) stop("the prior value for nu2 has missing values.", call.=FALSE)       


    #### Format and check the MCMC quantities
    if(is.null(burnin)) stop("the burnin argument is missing", call.=FALSE)
    if(is.null(n.sample)) stop("the n.sample argument is missing", call.=FALSE)
    if(!is.numeric(burnin)) stop("burn-in is not a number", call.=FALSE)
    if(!is.numeric(n.sample)) stop("n.sample is not a number", call.=FALSE) 
    if(!is.numeric(thin)) stop("thin is not a number", call.=FALSE)
    if(n.sample <= 0) stop("n.sample is less than or equal to zero.", call.=FALSE)
    if(burnin < 0) stop("burn-in is less than zero.", call.=FALSE)
    if(thin <= 0) stop("thin is less than or equal to zero.", call.=FALSE)
    if(n.sample <= burnin)  stop("Burn-in is greater than n.sample.", call.=FALSE)
    if(n.sample <= thin)  stop("thin is greater than n.sample.", call.=FALSE)
    if(burnin!=round(burnin)) stop("burnin is not an integer.", call.=FALSE) 
    if(n.sample!=round(n.sample)) stop("n.sample is not an integer.", call.=FALSE) 
    if(thin!=round(thin)) stop("thin is not an integer.", call.=FALSE) 
    
        
## Check for errors on rho and fix.rho
if(!is.logical(fix.rho.S)) stop("fix.rho.S is not logical.", call.=FALSE)   
if(fix.rho.S & is.null(rho.S)) stop("rho.S is fixed but an initial value was not set.", call.=FALSE)   
if(fix.rho.S & !is.numeric(rho.S) ) stop("rho.S is not numeric.", call.=FALSE)  
if(rho<0 ) stop("rho.S is outside the range [0, 1].", call.=FALSE)  
if(rho>1 ) stop("rho.S is outside the range [0, 1].", call.=FALSE)  

## Check for errors on rho and fix.rho
if(!is.logical(fix.rho.T)) stop("fix.rho.T is not logical.", call.=FALSE)   
if(fix.rho.T & is.null(rho.T)) stop("rho.T is fixed but an initial value was not set.", call.=FALSE)   
if(fix.rho.T & !is.numeric(rho.T) ) stop("rho.T is not numeric.", call.=FALSE)  
if(gamma<0 ) stop("rho.T is outside the range [0, 1].", call.=FALSE)  
if(gamma>1 ) stop("rho.T is outside the range [0, 1].", call.=FALSE)  


#### Set up matrices to store samples
n.keep <- floor((n.sample - burnin)/thin)
samples.beta <- array(NA, c(n.keep, p))
samples.phi <- array(NA, c(n.keep, N.all))
samples.tau2 <- array(NA, c(n.keep, 1))
samples.nu2 <- array(NA, c(n.keep, 1))
if(!fix.rho.S) samples.rho <- array(NA, c(n.keep, 1))
if(!fix.rho.T) samples.gamma <- array(NA, c(n.keep, 1))
samples.fitted <- array(NA, c(n.keep, N.all))
samples.like <- array(NA, c(n.keep, N.all))
samples.deviance <- array(NA, c(n.keep, 1))
if(n.miss>0) samples.Y <- array(NA, c(n.keep, n.miss))

    
    
#### Specify the Metropolis quantities
accept.all <- rep(0,2)
accept <- accept.all
proposal.sd.rho <- 0.05
tau2.shape <- prior.tau2[1] + N.all/2
nu2.shape <- prior.nu2[1] + N.all/2        
    
    


#### Spatial quantities
    ## Create the triplet object
    W.triplet <- c(NA, NA, NA)
    for(i in 1:K)
    {
        for(j in 1:K)
        {
            if(W[i,j]>0)
            {
                W.triplet <- rbind(W.triplet, c(i,j, W[i,j]))     
            }else{}
        }
    }
    W.triplet <- W.triplet[-1, ]     
    W.n.triplet <- nrow(W.triplet) 
    W.triplet.sum <- tapply(W.triplet[ ,3], W.triplet[ ,1], sum)
    W.neighbours <- tapply(W.triplet[ ,3], W.triplet[ ,1], length)
    
    
    ## Create the start and finish points for W updating
    W.begfin <- array(NA, c(K, 2))     
    temp <- 1
    for(i in 1:K)
    {
        W.begfin[i, ] <- c(temp, (temp + W.neighbours[i]-1))
        temp <- temp + W.neighbours[i]
    }
    
    
    ## Create the determinant     
    if(!fix.rho.S) 
    {
        Wstar <- diag(apply(W,1,sum)) - W
        Wstar.eigen <- eigen(Wstar)
        Wstar.val <- Wstar.eigen$values
        det.Q.W <-  0.5 * sum(log((rho * Wstar.val + (1-rho))))     
    }else
    {}
    
    
    #### Specify quantities that do not change
    offset.mat <- matrix(offset, nrow=K, ncol=N, byrow=FALSE) 
    regression.mat <- matrix(X.standardised %*% beta, nrow=K, ncol=N, byrow=FALSE)
    Y.mat <- matrix(Y, nrow=K, ncol=N, byrow=FALSE) 
    Y.mat.miss <- matrix(Y.miss, nrow=K, ncol=N, byrow=FALSE)
    phi.mat <- matrix(phi, nrow=K, ncol=N, byrow=FALSE)   
    
    
    #### Beta update quantities
    data.precision.beta <- t(X.short) %*% X.short
    if(length(prior.var.beta)==1)
    {
        prior.precision.beta <- 1 / prior.var.beta
    }else
    {
        prior.precision.beta <- solve(diag(prior.var.beta))
    }
    
    
    
    ## Check for islands
    W.list<- mat2listw(W)
    W.nb <- W.list$neighbours
    W.islands <- n.comp.nb(W.nb)
    islands <- W.islands$comp.id
    n.islands <- max(W.islands$nc)
    if(rho==1 & gamma==1) 
    {
        tau2.phi.shape <- prior.tau2[1] + prior.tau2[1] + ((N-1) * (K-1))/2
    }else if(rho==1)
    {
        tau2.phi.shape <- prior.tau2[1] + prior.tau2[1] + (N * (K-1))/2        
    }else if(gamma==1)
    {
        tau2.phi.shape <- prior.tau2[1] + prior.tau2[1] + ((N-1) * K)/2          
    }else
    {}
    
    


    ###########################
    #### Run the Bayesian model
    ###########################
    ## Start timer
    if(verbose)
    {
        cat("Generating", n.sample, "samples\n", sep = " ")
        progressBar <- txtProgressBar(style = 3)
        percentage.points<-round((1:100/100)*n.sample)
    }else
    {
        percentage.points<-round((1:100/100)*n.sample)     
    }
    
    
    
    for(j in 1:n.sample)
    {
        ##################
        ## Sample from nu2
        ##################
        nu2.offset <- as.numeric(Y.mat - offset.mat - regression.mat - phi.mat)[which.miss==1]
        nu2.scale <- prior.nu2[2]  + sum(nu2.offset^2)/2
        nu2 <- 1 / rgamma(1, nu2.shape, scale=(1/nu2.scale)) 

        
        ####################
        ## Sample from beta
        ####################
        fc.precision <- prior.precision.beta + data.precision.beta / nu2
        fc.var <- solve(fc.precision)
        beta.offset <- as.numeric(Y.mat - offset.mat - phi.mat)[which.miss==1]
        beta.offset2 <- t(X.short) %*% beta.offset / nu2 + prior.precision.beta %*% prior.mean.beta
        fc.mean <- fc.var %*% beta.offset2
        chol.var <- t(chol(fc.var))
        beta <- fc.mean + chol.var %*% rnorm(p)        
        regression.mat <- matrix(X.standardised %*% beta, nrow=K, ncol=N, byrow=FALSE)  

        
        
        
        ####################
        ## Sample from phi
        ####################
        phi.offset <- Y.mat.miss - offset.mat - regression.mat
        den.offset <- rho * W.triplet.sum + 1 - rho
        phi.temp <- gaussianarcarupdate(W.triplet, W.begfin, W.triplet.sum,  K, N, phi.mat, tau2, nu2, gamma, rho, phi.offset, den.offset, which.miss.mat)      
        phi <- as.numeric(phi.temp)  - mean(as.numeric(phi.temp))
        phi.mat <- matrix(phi, nrow=K, ncol=N, byrow=FALSE)

        
        
        
        ####################
        ## Sample from gamma
        ####################
        if(!fix.rho.T)
        {
        temp2 <- gammaquadformcompute(W.triplet, W.triplet.sum, W.n.triplet,  K, N, phi.mat, rho)
        mean.gamma <- temp2[[1]] / temp2[[2]]
        sd.gamma <- sqrt(tau2 / temp2[[2]])
        gamma <- rtrunc(n=1, spec="norm", a=0, b=1, mean=mean.gamma, sd=sd.gamma)
        }else
        {}
        
        
        
        ####################
        ## Samples from tau2
        ####################
        temp3 <- tauquadformcompute(W.triplet, W.triplet.sum, W.n.triplet,  K, N, phi.mat, rho, gamma)
        tau2.scale <- temp3 + prior.tau2[2] 
        tau2 <- 1 / rgamma(1, tau2.shape, scale=(1/tau2.scale)) 
        
        
        
        ##################
        ## Sample from rho
        ##################
        if(!fix.rho.S)
        {
        proposal.rho <- rtrunc(n=1, spec="norm", a=0, b=1, mean=rho, sd=proposal.sd.rho)
        temp4 <- tauquadformcompute(W.triplet, W.triplet.sum, W.n.triplet,  K, N, phi.mat, proposal.rho, gamma)
        det.Q.W.proposal <- 0.5 * sum(log((proposal.rho * Wstar.val + (1-proposal.rho))))
        logprob.current <- N * det.Q.W - temp3 / tau2
        logprob.proposal <- N * det.Q.W.proposal - temp4 / tau2
        prob <- exp(logprob.proposal - logprob.current)
        if(prob > runif(1))
        {
            rho <- proposal.rho
            det.Q.W <- det.Q.W.proposal
            accept[1] <- accept[1] + 1           
        }else
        {
        }              
        accept[2] <- accept[2] + 1       
        }else
        {}
        
        
        #########################
        ## Calculate the deviance
        #########################
        fitted <- as.numeric(offset.mat + regression.mat + phi.mat)
        deviance.all <- dnorm(Y, mean = fitted, sd = rep(sqrt(nu2),N.all), log=TRUE)
        like <- exp(deviance.all)
        deviance <- -2 * sum(deviance.all, na.rm=TRUE)        

        
        
        ###################
        ## Save the results
        ###################
        if(j > burnin & (j-burnin)%%thin==0)
        {
            ele <- (j - burnin) / thin
            samples.beta[ele, ] <- beta
            samples.phi[ele, ] <- as.numeric(phi)
            if(!fix.rho.S) samples.rho[ele, ] <- rho
            if(!fix.rho.T) samples.gamma[ele, ] <- gamma
            samples.tau2[ele, ] <- tau2
            samples.nu2[ele, ] <- nu2
            samples.deviance[ele, ] <- deviance
            samples.fitted[ele, ] <- fitted
            samples.like[ele, ] <- like
            if(n.miss>0) samples.Y[ele, ] <- rnorm(n=n.miss, mean=fitted[which.miss==0], sd=sqrt(nu2))
        }else
        {
        }
        
        
        
        ########################################
        ## Self tune the acceptance probabilties
        ########################################
        k <- j/100
        if(ceiling(k)==floor(k))
        {
            #### Determine the acceptance probabilities
            accept.rho <- 100 * accept[1] / accept[2]
            if(is.na(accept.rho)) accept.rho <- 45
            accept.all <- accept.all + accept
            accept <- rep(0,2)
                        
            #### rho tuning parameter
            if(accept.rho > 50)
            {
                proposal.sd.rho <- min(proposal.sd.rho + 0.1 * proposal.sd.rho, 0.5)
            }else if(accept.rho < 40)              
            {
                proposal.sd.rho <- proposal.sd.rho - 0.1 * proposal.sd.rho
            }else
            {
            }   
        }else
        {   
        }
        
        
        
        ################################       
        ## print progress to the console
        ################################
        if(j %in% percentage.points & verbose)
        {
            setTxtProgressBar(progressBar, j/n.sample)
        }
    }
    
    # end timer
    if(verbose)
    {
        cat("\nSummarising results")
        close(progressBar)
    }else
    {}
    
    
###################################
#### Summarise and save the results 
###################################
## Compute the acceptance rates
    if(!fix.rho.S)
    {
        accept.rho <- 100 * accept.all[1] / accept.all[2]
    }else
    {
        accept.rho <- NA    
    }
accept.phi <- 100
accept.beta <- 100
accept.final <- c(accept.beta, accept.phi, accept.rho, 100)
names(accept.final) <- c("beta", "phi", "rho.S", "rho.T")
    
    
## Compute information criterion (DIC, DIC3, WAIC)
median.beta <- apply(samples.beta,2,median)
regression.mat <- matrix(X.standardised %*% median.beta, nrow=K, ncol=N, byrow=FALSE)   
median.phi <- matrix(apply(samples.phi, 2, median), nrow=K, ncol=N)
fitted.median <- as.numeric(offset.mat + median.phi + regression.mat)
nu2.median <- median(samples.nu2)
deviance.fitted <- -2 * sum(dnorm(Y, mean = fitted.median, sd = rep(sqrt(nu2.median),N.all), log = TRUE), na.rm=TRUE)
p.d <- median(samples.deviance) - deviance.fitted
DIC <- 2 * median(samples.deviance) - deviance.fitted    


#### Watanabe-Akaike Information Criterion (WAIC)
LPPD <- sum(log(apply(samples.like,2,mean)), na.rm=TRUE)
p.w <- sum(apply(log(samples.like),2,var), na.rm=TRUE)
WAIC <- -2 * (LPPD - p.w)


#### Compute the Conditional Predictive Ordinate  
CPO <- rep(NA, N.all)
    for(j in 1:N.all)
    {
    CPO[j] <- 1/median((1 / dnorm(Y[j], mean=samples.fitted[ ,j], sd=sqrt(samples.nu2))))    
    }
LMPL <- sum(log(CPO), na.rm=TRUE)   
    
    
## Create the Fitted values
fitted.values <- apply(samples.fitted, 2, median)
residuals <- as.numeric(Y) - fitted.values
    
    
#### transform the parameters back to the origianl covariate scale.
samples.beta.orig <- samples.beta
number.cts <- sum(X.indicator==1)     
    if(number.cts>0)
    {
        for(r in 1:p)
        {
            if(X.indicator[r]==1)
            {
                samples.beta.orig[ ,r] <- samples.beta[ ,r] / X.sd[r]
            }else if(X.indicator[r]==2 & p>1)
            {
                X.transformed <- which(X.indicator==1)
                samples.temp <- as.matrix(samples.beta[ ,X.transformed])
                for(s in 1:length(X.transformed))
                {
                    samples.temp[ ,s] <- samples.temp[ ,s] * X.mean[X.transformed[s]]  / X.sd[X.transformed[s]]
                }
                intercept.adjustment <- apply(samples.temp, 1,sum) 
                samples.beta.orig[ ,r] <- samples.beta[ ,r] - intercept.adjustment
            }else
            {
            }
        }
    }else
    {
    }
    
    
#### Create a summary object
samples.beta.orig <- mcmc(samples.beta.orig)
summary.beta <- t(apply(samples.beta.orig, 2, quantile, c(0.5, 0.025, 0.975))) 
summary.beta <- cbind(summary.beta, rep(n.keep, p), rep(100,p), effectiveSize(samples.beta.orig), geweke.diag(samples.beta.orig)$z)
rownames(summary.beta) <- colnames(X)
colnames(summary.beta) <- c("Median", "2.5%", "97.5%", "n.sample", "% accept", "n.effective", "Geweke.diag")
    
summary.hyper <- array(NA, c(4, 7))     
summary.hyper[1,1:3] <- quantile(samples.tau2, c(0.5, 0.025, 0.975))
summary.hyper[2,1:3] <- quantile(samples.nu2, c(0.5, 0.025, 0.975))

rownames(summary.hyper) <- c("tau2", "nu2", "rho.S", "rho.T")     
summary.hyper[1, 4:7] <- c(n.keep, 100, effectiveSize(mcmc(samples.tau2)), geweke.diag(mcmc(samples.tau2))$z)     
summary.hyper[2, 4:7] <- c(n.keep, 100, effectiveSize(mcmc(samples.nu2)), geweke.diag(mcmc(samples.nu2))$z)     

if(!fix.rho.S)
{
    summary.hyper[3,1:3] <- quantile(samples.rho, c(0.5, 0.025, 0.975))
    summary.hyper[3, 4:7] <- c(n.keep, accept.rho, effectiveSize(mcmc(samples.rho)), geweke.diag(mcmc(samples.rho))$z)  
}else
{
    summary.hyper[3, 1:3] <- c(rho, rho, rho)
    summary.hyper[3, 4:7] <- rep(NA, 4)
}

if(!fix.rho.T)
{
    summary.hyper[4,1:3] <- quantile(samples.gamma, c(0.5, 0.025, 0.975))
    summary.hyper[4, 4:7] <- c(n.keep, 100, effectiveSize(mcmc(samples.gamma)), geweke.diag(mcmc(samples.gamma))$z)  
}else
{
    summary.hyper[4, 1:3] <- c(gamma, gamma, gamma)
    summary.hyper[4, 4:7] <- rep(NA, 4)
}   




summary.results <- rbind(summary.beta, summary.hyper)
summary.results[ , 1:3] <- round(summary.results[ , 1:3], 4)
summary.results[ , 4:7] <- round(summary.results[ , 4:7], 1)
    
    
## Compile and return the results
modelfit <- c(DIC, p.d, WAIC, p.w, LMPL)
names(modelfit) <- c("DIC", "p.d", "WAIC", "p.w", "LMPL")
if(fix.rho.S & fix.rho.T)
{
    samples.rhoext <- NA
}else if(fix.rho.S & !fix.rho.T)
{
    samples.rhoext <- samples.gamma
    names(samples.rhoext) <- "rho.T"
}else if(!fix.rho.S & fix.rho.T)
{
    samples.rhoext <- samples.rho  
    names(samples.rhoext) <- "rho.S"
}else
{
    samples.rhoext <- cbind(samples.rho, samples.gamma)
    colnames(samples.rhoext) <- c("rho.S", "rho.T")
}
if(n.miss==0) samples.Y = NA


samples <- list(beta=mcmc(samples.beta.orig), phi=mcmc(samples.phi),  rho=mcmc(samples.rhoext), tau2=mcmc(samples.tau2), nu2=mcmc(samples.nu2), fitted=mcmc(samples.fitted), Y=mcmc(samples.Y))
model.string <- c("Likelihood model - Gaussian (identity link function)", "\nLatent structure model - Autoregressive CAR model\n")
results <- list(summary.results=summary.results, samples=samples, fitted.values=fitted.values, residuals=residuals, modelfit=modelfit, accept=accept.final, localised.structure=NULL, formula=formula, model=model.string,  X=X)
class(results) <- "carbayesST"
    if(verbose)
    {
        b<-proc.time()
        cat(" finished in ", round(b[3]-a[3], 1), "seconds")
    }else
    {}
    return(results)
}
