#' Test whether a metric has enough spread to discriminate between players (H3)
#'
#' Even a metric that is neither redundant (H1) nor unreliable (H2) can fail
#' to be useful if it barely varies across players -- everyone looks about
#' the same, so ranking is meaningless. What matters for ranking is the
#' spread in players' TRUE talent, not the spread you happen to observe,
#' because observed spread also contains measurement noise (luck).
#'
#' When a reliability estimate is supplied (e.g. the Spearman-Brown
#' reliability from \code{test_reliability}), observed variance is split
#' into a signal component and a noise component:
#' \itemize{
#'   \item \code{true_sd = sqrt(reliability * observed_var)} -- the spread
#'     that reflects real talent differences. This is the main result.
#'   \item \code{noise_sd = sqrt((1 - reliability) * observed_var)} -- the
#'     spread attributable to measurement noise.
#'   \item \code{signal_to_noise = true_sd / noise_sd} -- a unitless ratio
#'     that can be compared across metrics measured on different scales.
#' }
#'
#' The reliability you supply must describe the same metric, measured over
#' the same number of observations per player, as the values in \code{data}.
#' A reliability computed on 30-observation samples says nothing reliable
#' about full-season values.
#'
#' @section Why there is no coefficient of variation by default:
#' The coefficient of variation (sd / mean) is only meaningful for metrics on
#' a ratio scale, where zero means "none of it" (home runs, minutes played).
#' Many advanced metrics are centered on an arbitrary zero (WPA, plus/minus,
#' EPA, BPM). For those, moving the zero changes the mean but not the spread,
#' so cv changes -- even flips sign -- while the players are exactly the same,
#' and it blows up as the mean approaches 0. For example, the WPA values
#' \code{c(1.8, -0.6, 0.3, -1.2, 0.2)} have sd = 1.13 and cv = 11.3; subtract
#' 0.2 from every value and the sd is still 1.13 but cv becomes -11.3.
#' Because this package is sport-agnostic, \code{cv} is therefore only
#' returned when you assert the metric has a true zero with
#' \code{ratio_scale = TRUE}. \code{sd}, \code{true_sd}, \code{noise_sd} and
#' \code{signal_to_noise} are unaffected by where zero sits.
#'
#' Note that \code{true_sd} and \code{noise_sd} are in the metric's own
#' units, so they cannot be compared directly between, say, WPA and wRC+.
#' Use \code{signal_to_noise} (or the reliability itself) for that.
#'
#' @param data A data frame with one row per player (or player-season).
#' @param metric Character. Column name of the metric to test.
#' @param reliability Optional numeric between 0 and 1 (e.g. the
#'   Spearman-Brown reliability from \code{test_reliability}). Required for
#'   the signal/noise decomposition; if omitted, only observed spread is
#'   reported and a message says so.
#' @param ratio_scale Logical. Set to \code{TRUE} only if zero on this metric
#'   means "none of it" (counts, rates, minutes). Adds \code{cv} to the
#'   result. Errors if the metric has negative values or a mean of zero.
#'   Default \code{FALSE}.
#'
#' @return A list with:
#'   \item{mean}{mean of the metric}
#'   \item{sd}{observed standard deviation of the metric (includes noise)}
#'   \item{range}{min and max}
#'   \item{cv}{(only if \code{ratio_scale = TRUE}) sd / mean}
#'   \item{reliability}{(only if reliability supplied) the value you passed}
#'   \item{true_sd}{(only if reliability supplied) estimated signal-only
#'     standard deviation -- the spread that reflects real talent
#'     differences}
#'   \item{noise_sd}{(only if reliability supplied) the spread attributable
#'     to measurement noise}
#'   \item{signal_to_noise}{(only if reliability supplied) true_sd / noise_sd.
#'     \code{Inf} when reliability is 1, \code{NaN} if the metric is constant.}
#'
#' @examples
#' # A metric centered on an arbitrary zero (like WPA)
#' df <- data.frame(wpa = c(1.8, -0.6, 0.3, -1.2, 0.2))
#' test_discriminability(df, "wpa", reliability = 0.7)
#'
#' # Moving the zero changes none of the spread statistics
#' df$wpa_shifted <- df$wpa - 0.2
#' test_discriminability(df, "wpa_shifted", reliability = 0.7)
#'
#' # A count stat with a true zero: cv is meaningful, so opt in
#' set.seed(1)
#' hr <- data.frame(hr = rpois(200, lambda = 15))
#' test_discriminability(hr, "hr", reliability = 0.8, ratio_scale = TRUE)
#'
#' @export
test_discriminability <- function(data, metric, reliability = NULL, ratio_scale = FALSE) {
  stopifnot(is.data.frame(data))
  if (!metric %in% names(data)) stop("metric column not found in data")
  if (!is.logical(ratio_scale) || length(ratio_scale) != 1 || is.na(ratio_scale)) {
    stop("ratio_scale must be TRUE or FALSE")
  }

  x <- data[[metric]]
  x <- x[!is.na(x)]

  result <- list(
    mean = mean(x),
    sd = stats::sd(x),
    range = range(x)
  )

  if (ratio_scale) {
    if (any(x < 0)) {
      stop(
        "ratio_scale = TRUE but the metric has negative values, so zero cannot ",
        "mean 'none of it'. Use ratio_scale = FALSE and rely on true_sd or ",
        "signal_to_noise instead of cv."
      )
    }
    if (mean(x) == 0) {
      stop("ratio_scale = TRUE but the mean of the metric is zero, so cv is undefined")
    }
    result$cv <- stats::sd(x) / mean(x)
  }

  if (is.null(reliability)) {
    message(
      "No reliability supplied: reporting observed spread only. Pass ",
      "`reliability` (e.g. from test_reliability()) to separate true talent ",
      "spread from noise."
    )
  } else {
    if (!is.numeric(reliability) || length(reliability) != 1 || is.na(reliability) ||
        reliability < 0 || reliability > 1) {
      stop("reliability must be a single number between 0 and 1")
    }
    observed_var <- stats::var(x)
    true_sd <- sqrt(reliability * observed_var)
    noise_sd <- sqrt((1 - reliability) * observed_var)

    result$reliability <- reliability
    result$true_sd <- true_sd
    result$noise_sd <- noise_sd
    result$signal_to_noise <- true_sd / noise_sd
  }

  result
}
