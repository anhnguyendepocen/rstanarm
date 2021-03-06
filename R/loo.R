# Part of the rstanarm package for estimating model parameters
# Copyright (C) 2015, 2016 Trustees of Columbia University
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#' Leave-one-out (LOO) and K-fold cross-validation
#' 
#' For models fit using MCMC, compute approximate leave-one-out cross-validation
#' (LOO) or, less preferably, the Widely Applicable Information Criterion (WAIC)
#' using the \pkg{\link[=loo-package]{loo}} package. Exact \eqn{K}-fold
#' cross-validation is also available. Compare two or more models using the
#' \code{\link[loo]{compare}} function.
#' 
#' @aliases loo waic compare
#'
#' @export
#' @templateVar stanregArg x
#' @template args-stanreg-object
#' @template reference-loo
#' 
#' @inheritParams loo::loo
#' @param k_threshold Threshold for flagging estimates of the Pareto shape 
#'   parameters \eqn{k} estimated by \code{loo}. See the \emph{How to proceed
#'   when \code{loo} gives warnings} section, below, for details.
#' 
#' @return An object of class 'loo'. See the 'Value' section in 
#'   \code{\link[loo]{loo}} and \code{\link[loo]{waic}} for details on the
#'   structure of these objects. The object returned by \code{kfold} also 
#'   has class 'kfold' in addition to 'loo'.
#'   
#' @section Approximate LOO CV:
#' The \code{loo} method for stanreg objects provides an interface to
#' the \pkg{\link[=loo-package]{loo}} package for approximate leave-one-out 
#' cross-validation (LOO). The LOO Information Criterion (LOOIC) has the same 
#' purpose as the Akaike Information Criterion (AIC) that is used by 
#' frequentists. Both are intended to estimate the expected log predictive 
#' density (ELPD) for a new dataset. However, the AIC ignores priors and assumes
#' that the posterior distribution is multivariate normal, whereas the functions
#' from the \pkg{loo} package do not make this distributional assumption and 
#' integrate over uncertainty in the parameters. This only assumes that any one 
#' observation can be omitted without having a major effect on the posterior 
#' distribution, which can be judged using the diagnostic plot provided by the 
#' \code{\link[loo]{plot.loo}} method and the warnings provided by the 
#' \code{\link[loo]{print.loo}} method (see the \emph{How to Use the rstanarm 
#' Package} vignette for an example of this process).
#' 
#' \subsection{How to proceed when \code{loo} gives warnings (k_threshold)}{
#' The \code{k_threshold} argument to the \code{loo} method for \pkg{rstanarm} 
#' models is provided as a possible remedy when the diagnostics reveal problems
#' stemming from the posterior's sensitivity to particular observations.
#' Warnings about Pareto \eqn{k} estimates indicate observations for which the
#' approximation to LOO is problematic (this is described in detail in Vehtari,
#' Gelman, and Gabry (2016) and the \pkg{\link[=loo-package]{loo}} package
#' documentation). The \code{k_threshold} argument can be used to set the
#' \eqn{k} value above which an observation is flagged. If \code{k_threshold} is
#' not \code{NULL} and there are \eqn{J} observations with \eqn{k} estimates
#' above \code{k_threshold} then when \code{loo} is called it will refit the
#' original model \eqn{J} times, each time leaving out one of the \eqn{J}
#' problematic observations. The pointwise contributions of these observations
#' to the total ELPD are then computed directly and substituted for the previous
#' estimates from these \eqn{J} observations that are stored in the object
#' created by \code{loo}.
#' 
#' \strong{Note}: in the warning messages issued by \code{loo} about large 
#' Pareto \eqn{k} estimates we recommend setting \code{k_threshold} to at least 
#' \eqn{0.7}. There is a theoretical reason, explained in Vehtari, Gelman, and 
#' Gabry (2016), for setting the threshold to the stricter value of \eqn{0.5}, 
#' but in practice they find that errors in the LOO approximation start to 
#' increase non-negligibly when \eqn{k > 0.7}.
#' }
#' 
#' @section K-fold CV:
#' The \code{kfold} function performs exact \eqn{K}-fold cross-validation. First
#' the data are randomly partitioned into \eqn{K} subsets of equal (or as close 
#' to equal as possible) size. Then the model is refit \eqn{K} times, each time 
#' leaving out one of the \code{K} subsets. If \eqn{K} is equal to the total 
#' number of observations in the data then \eqn{K}-fold cross-validation is 
#' equivalent to exact leave-one-out cross-validation (to which \code{loo} is an
#' efficient approximation). The \code{compare} function is also compatible with
#' the objects returned by \code{kfold}.
#'   
#' @seealso 
#' \itemize{
#'   \item \code{\link[loo]{compare}} for comparing two or more models on 
#'     LOO, WAIC, or \eqn{K}-fold CV.
#'   \item The various \pkg{rstanarm} vignettes for more examples of 
#'     using \code{loo}.
#'   \item \code{\link[loo]{loo-package}} (in particular the \emph{PSIS-LOO} 
#'     section)  for details on the computations implemented by the \pkg{loo} 
#'     package and the interpretation of the Pareto \eqn{k} estimates displayed 
#'     when using the  \code{\link{plot.loo}} method.
#'   \item \code{\link{log_lik.stanreg}} to directly access the pointwise 
#'     log-likelihood matrix. 
#' }
#'   
#' @examples 
#' \donttest{
#' fit1 <- stan_glm(mpg ~ wt, data = mtcars)
#' fit2 <- stan_glm(mpg ~ wt + cyl, data = mtcars)
#' 
#' # compare on LOOIC
#' (loo1 <- loo(fit1, cores = 2))
#' loo2 <- loo(fit2, cores = 2)
#' compare(loo1, loo2)
#' plot(loo2)
#' 
#' # 10-fold cross-validation
#' (kfold1 <- kfold(fit1, K = 10))
#' kfold2 <- kfold(fit2, K = 10)
#' compare(kfold1, kfold2)
#' }
#' @importFrom loo loo loo.function compare
#' 
loo.stanreg <- function(x, ..., k_threshold = NULL) {
  if (!used.sampling(x)) 
    STOP_sampling_only("loo")
  if (model_has_weights(x))
    recommend_exact_loo(reason = "model has weights")
  
  user_threshold <- !is.null(k_threshold)
  if (user_threshold) {
    validate_k_threshold(k_threshold)
  } else {
    k_threshold <- 0.7
  }
  
  loo_x <- suppressWarnings(loo.function(ll_fun(x), args = ll_args(x), ...))
  bad_obs <- which(loo_x[["pareto_k"]] > k_threshold)
  n_bad <- length(bad_obs)
  
  if (!length(bad_obs)) {
    if (user_threshold)
      message(
        "All pareto_k estimates below user-specified threshold of ", 
        k_threshold, ". \nReturning loo object."
      )
    return(loo_x)
  }
  
  if (!user_threshold) {
    if (n_bad > 10) {
      recommend_kfold(n_bad)
    } else {
      recommend_reloo(n_bad)
    }
    return(loo_x)
  }
  
  reloo(x, loo_x, obs = bad_obs)
}


#' @rdname loo.stanreg
#' @export
#' @param K The number of subsets of equal (if possible) size into which the 
#'   data will be randomly partitioned for performing \eqn{K}-fold 
#'   cross-validation. The model is refit \code{K} times, each time leaving out
#'   one of the \code{K} subsets. If \code{K} is equal to the total number of
#'   observations in the data then \eqn{K}-fold cross-validation is equivalent
#'   to exact leave-one-out cross-validation.
#'   
kfold <- function(x, K = 10) {
  validate_stanreg_object(x)
  stopifnot(K > 1, K <= nobs(x))
  if (!used.sampling(x)) 
    STOP_sampling_only("kfold")
  if (model_has_weights(x))
    stop("kfold is not currently available for models fit using weights.")
  
  d <- kfold_and_reloo_data(x)
  N <- nrow(d)
  
  perm <- sample.int(N)
  idx <- ceiling(seq(from = 1, to = N, length.out = K + 1))
  bin <- .bincode(perm, breaks = idx, right = FALSE, include.lowest = TRUE)
  
  lppds <- list()
  for (k in 1:K) {
    message("Fitting model ", k, " out of ", K)
    omitted <- which(bin == k)
    fit_k <- update.stanreg(
      object = x,
      data = d[-omitted,, drop=FALSE],
      weights = NULL,
      refresh = 0
    )
    lppds[[k]] <-
      log_lik.stanreg(fit_k, newdata = d[omitted, , drop = FALSE],
                      newx = get_x(x)[omitted, , drop = FALSE],
                      stanmat = as.matrix.stanreg(x))
  }
  elpds <- unlist(lapply(lppds, function(x) {
    apply(x, 2, log_mean_exp)
  }))
  
  out <- list(
    elpd_kfold = sum(elpds),
    se_elpd_kfold = sqrt(N * var(elpds)),
    pointwise = cbind(elpd_kfold = elpds)
  )
  structure(out, class = c("kfold", "loo"), K = K)
}

#' Print method for kfold
#' 
#' @keywords internal
#' @export
#' @method print kfold
#' @param x,digits,... See \code{\link{print}}.
print.kfold <- function(x, digits = 1, ...) {
  cat("\n", paste0(attr(x, "K"), "-fold"), "cross-validation\n\n")
  out <- data.frame(Estimate = x$elpd_kfold, SE = x$se_elpd_kfold, 
                    row.names = "elpd_kfold")
  .printfr(out, digits)
  invisible(x)
}

#' @rdname loo.stanreg
#' @export
#' @importFrom loo waic waic.function
#' @note The \code{...} is ignored for \code{waic}.
#' 
waic.stanreg <- function(x, ...) {
  if (!used.sampling(x)) 
    STOP_sampling_only("waic")
  waic.function(ll_fun(x), args = ll_args(x))
}



# internal ----------------------------------------------------------------
validate_k_threshold <- function(k) {
  if (!is.numeric(k) || length(k) != 1) {
    stop("'k_threshold' must be a single numeric value.", 
         call. = FALSE)
  } else if (k < 0) {
    stop("'k_threshold' < 0 not allowed.", 
         call. = FALSE)
  } else if (k > 1) {
    warning(
      "Setting 'k_threshold' > 1 is not recommended.", 
      "\nFor details see the PSIS-LOO section in help('loo-package', 'loo').",
      call. = FALSE
    )
  }
}
recommend_kfold <- function(n) {
  warning(
    "Found ", n, " observations with a pareto_k > 0.7. ",
    "With this many problematic observations we recommend calling ",
    "'kfold' with argument 'K=10' to perform 10-fold cross-validation ",
    "rather than LOO.", 
    call. = FALSE
  )
}
recommend_reloo <- function(n) {
  warning(
    "Found ", n, " observation(s) with a pareto_k > 0.7. ",
    "We recommend calling 'loo' again with argument 'k_threshold = 0.7' ",
    "in order to calculate the ELPD without the assumption that ", 
    "these observations are negligible. ", "This will refit the model ", 
    n, " times to compute the ELPDs for the problematic observations directly.",
    call. = FALSE
  )
}
recommend_exact_loo <- function(reason) {
  stop(
    "'loo' is not supported if ", reason, ". ", 
    "If refitting the model 'nobs(x)' times is feasible, ", 
    "we recommend calling 'kfold' with K equal to the ", 
    "total number of observations in the data to perform exact LOO-CV.",
    call. = FALSE
  )
}


# Refit model leaving out specific observations
#
# @param x stanreg object
# @param loo_x result of loo(x)
# @param obs vector of observation indexes
# @param ... unused currently
# @param refit logical, to toggle whether refitting actually happens (only used
#   to avoid refitting in tests)
reloo <- function(x, loo_x, obs, ..., refit = TRUE) {
  stopifnot(!is.null(x$data), inherits(loo_x, "loo"))
  if (is.null(loo_x$pareto_k))
    stop("No Pareto k estimates found in 'loo' object.")
  
  J <- length(obs)
  d <- kfold_and_reloo_data(x)
  lls <- vector("list", J)
  message(
    J, " problematic observation(s) found.", 
    "\nModel will be refit ", J, " times."
  )
  
  if (!refit)
    return(NULL)
  
  for (j in 1:J) {
    message(
      "\nFitting model ", j, " out of ", J,
      " (leaving out observation ", obs[j], ")"
    )
    omitted <- obs[j]
    fit_j <- suppressWarnings(update(x, data = d[-omitted, , drop=FALSE], refresh = 0))
    lls[[j]] <-
      log_lik.stanreg(fit_j, newdata = d[omitted, , drop = FALSE],
                      newx = get_x(x)[omitted, , drop = FALSE],
                      stanmat = as.matrix.stanreg(x))
  }
  
  # replace parts of loo_x
  sel <- c("elpd_loo", "looic")
  elppds <- unlist(lapply(lls, log_mean_exp))
  loo_x$pointwise[obs, sel] <- cbind(elppds, -2 * elppds)
  loo_x[sel] <- with(loo_x, colSums(pointwise[, sel]))
  loo_x[paste0("se_", sel)] <- with(loo_x, {
    N <- nrow(pointwise)
    sqrt(N * apply(pointwise[, sel], 2, var))
  })
  
  # what should we do about pareto k's? for now setting them to 0
  loo_x$pareto_k[obs] <- 0
  loo_x
}

log_mean_exp <- function(x) {
  max_x <- max(x)
  max_x + log(sum(exp(x - max_x))) - log(length(x))
}

# Get correct data to use for kfold and reloo 
# 
# @param x stanreg object
# @return data frame
kfold_and_reloo_data <- function(x) {
  d <- get_all_vars(formula(x), x[["data"]])
  na.omit(d)
}
