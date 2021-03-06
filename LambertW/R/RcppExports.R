# This file was generated by Rcpp::compileAttributes
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#' @rdname estimate-moments
#' @description
#' \code{kurtosis} estimates the fourth central, normalized moment from data.
#' 
#' @export
kurtosis <- function(x) {
    .Call('LambertW_kurtosis', PACKAGE = 'LambertW', x)
}

lp_norm_Cpp <- function(x, p) {
    .Call('LambertW_lp_norm_Cpp', PACKAGE = 'LambertW', x, p)
}

lp_norm_complex_Cpp <- function(x, p) {
    .Call('LambertW_lp_norm_complex_Cpp', PACKAGE = 'LambertW', x, p)
}

normalize_by_tau_Cpp <- function(x, mu_x, sigma_x, inverse) {
    .Call('LambertW_normalize_by_tau_Cpp', PACKAGE = 'LambertW', x, mu_x, sigma_x, inverse)
}

#' @title Skewness and kurtosis
#' @rdname estimate-moments
#' @description
#' \code{skewness} estimates the third central, normalized moment from data.
#' 
#' @param x a numeric vector.
#' @seealso Corresponding functions in the \pkg{moments} package.
#' @export
skewness <- function(x) {
    .Call('LambertW_skewness', PACKAGE = 'LambertW', x)
}

W_Cpp <- function(z, branch) {
    .Call('LambertW_W_Cpp', PACKAGE = 'LambertW', z, branch)
}

W_delta_Cpp <- function(z, delta) {
    .Call('LambertW_W_delta_Cpp', PACKAGE = 'LambertW', z, delta)
}

W_delta_alpha_Cpp <- function(z, delta, alpha) {
    .Call('LambertW_W_delta_alpha_Cpp', PACKAGE = 'LambertW', z, delta, alpha)
}

W_gamma_Cpp <- function(z, gamma, branch) {
    .Call('LambertW_W_gamma_Cpp', PACKAGE = 'LambertW', z, gamma, branch)
}

# Register entry points for exported C++ functions
methods::setLoadAction(function(ns) {
    .Call('LambertW_RcppExport_registerCCallable', PACKAGE = 'LambertW')
})
