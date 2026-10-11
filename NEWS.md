# sportmetrics 0.2.0

## Breaking changes

* `test_discriminability()` no longer returns `cv` by default. The
  coefficient of variation (sd / mean) is only meaningful when zero means
  "none of it". On metrics centered on an arbitrary zero (WPA, plus/minus,
  EPA, BPM, ...), shifting the zero changes the mean but not the spread, so
  `cv` changed -- and could flip sign or blow up near a zero mean -- while
  the players were identical. `true_sd`, `noise_sd` and `signal_to_noise`
  are now the main results.
* `cv` is still available for metrics with a true zero (home runs, minutes
  played) by passing `ratio_scale = TRUE`. It errors if the metric has
  negative values or a mean of zero.

## New

* `test_discriminability()` gains a `ratio_scale` argument (see above).
* `test_discriminability()` now also returns `reliability` and
  `signal_to_noise` (`true_sd / noise_sd`, unitless, comparable across
  metrics) when `reliability` is supplied.
* `test_discriminability()` prints a message when `reliability` is omitted,
  since only observed spread (which includes noise) can be reported then.

## Fixes

* `noise_sd` is computed as `sqrt((1 - reliability) * observed_var)` rather
  than by subtraction, which could produce a tiny negative variance from
  floating-point error at reliability = 1.
* `reliability` is validated as a single number between 0 and 1.
