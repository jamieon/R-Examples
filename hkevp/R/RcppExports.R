# This file was generated by Rcpp::compileAttributes
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

MCMC <- function(Y, sites, spatial_covariates, knots, dsk, dss, niter, nburn, nthin, trace, gev_vary, gev_init, alpha_init, tau_init, A_init, B_init, sills_init, ranges_init, constant_gev_prior, alpha_prior, tau_prior, beta_variance_prior, sill_prior, range_prior, gev_random_walk, range_random_walk, tau_random_walk, alpha_random_walk, A_random_walk, B_random_walk, quiet, latent_processes_correlation_type, nas) {
    .Call('hkevp_MCMC', PACKAGE = 'hkevp', Y, sites, spatial_covariates, knots, dsk, dss, niter, nburn, nthin, trace, gev_vary, gev_init, alpha_init, tau_init, A_init, B_init, sills_init, ranges_init, constant_gev_prior, alpha_prior, tau_prior, beta_variance_prior, sill_prior, range_prior, gev_random_walk, range_random_walk, tau_random_walk, alpha_random_walk, A_random_walk, B_random_walk, quiet, latent_processes_correlation_type, nas)
}

