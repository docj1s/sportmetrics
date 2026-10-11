# sportmetrics

Three reusable functions for testing whether an "advanced" sports metric
actually adds value over a traditional stat, or fails in one of three ways:

| Function | Hypothesis | Question it answers |
|---|---|---|
| `test_redundancy()` | H1 — Redundant | Does the advanced metric predict an outcome better than traditional stats alone? |
| `test_reliability()` | H2 — Too noisy | Is the metric stable enough, split-half, to trust for ranking? |
| `test_discriminability()` | H3 — No real spread | How much of the spread across players is real talent rather than noise, and is there enough of it to rank players at all? |

These functions are sport-agnostic. The same three functions get called on
baseball, football, and basketball data — only the data changes.

## Install

Clone the repo, then from R:

```r
# install.packages("devtools") # if you don't already have it
devtools::load_all(".")
```

Or, once this is pushed to GitHub:

```r
devtools::install_github("<your-github-username>/sportmetrics")
```

## Quick start

```r
library(sportmetrics)

# H1: is wRC+ redundant with AVG/HR/RBI for predicting next-season WAR?
test_redundancy(
  data = player_season_data,
  outcome = "next_season_war",
  traditional_vars = c("avg", "hr", "rbi"),
  advanced_var = "wrc_plus"
)

# H2: is wOBA reliable split-half across plate appearances?
rel <- test_reliability(
  data = plate_appearance_data,   # long format: one row per PA per player
  id_col = "player_id",
  value_col = "wOBA_value",
  n_splits = 1000
)

# H3: how much of the spread in wOBA is real talent vs. noise?
# Pass the reliability of the SAME metric, measured over the same number of
# observations per player as the values in player_season_data.
test_discriminability(
  data = player_season_data,
  metric = "woba",
  reliability = rel$spearman_brown_r
)
```

## Reading the `test_discriminability()` output

| Field | Meaning |
|---|---|
| `sd` | Observed spread across players. Includes luck, so on its own it overstates how much players really differ. |
| `true_sd` | **Main result.** Estimated spread from real talent differences: `sqrt(reliability * observed_var)`. In the metric's own units. |
| `noise_sd` | Spread attributable to measurement noise: `sqrt((1 - reliability) * observed_var)`. |
| `signal_to_noise` | `true_sd / noise_sd`. Unitless, so it can be compared across metrics on different scales. |
| `cv` | Only returned with `ratio_scale = TRUE` (see below). |

`true_sd`, `noise_sd` and `signal_to_noise` need a `reliability` value. If you
leave it out you get observed `sd` only, plus a message saying so.

`true_sd` is in the metric's own units, so a `true_sd` of 0.4 for WPA and 12
for wRC+ cannot be compared directly. Use `signal_to_noise` (or the
reliability itself) to compare metrics.

### Why there is no coefficient of variation by default

The coefficient of variation (sd / mean) only makes sense when zero means
"none of it" — home runs, minutes played. Many advanced metrics are centered
on an arbitrary zero (WPA, plus/minus, EPA, BPM). Moving the zero changes the
mean but not the spread, so cv changes even though the players are identical:

```r
df <- data.frame(wpa = c(1.8, -0.6, 0.3, -1.2, 0.2))
# sd = 1.13, cv = 11.3

df$wpa_minus_02 <- df$wpa - 0.2   # same players, zero moved by 0.2
# sd = 1.13, cv = -11.3
```

cv also blows up as the mean approaches 0. A warning on negative values would
not catch every case either (WPA + 10 has no negatives and a meaningless cv),
so `cv` is opt-in: pass `ratio_scale = TRUE` only for metrics with a true zero.
The function then errors if it sees negative values or a mean of zero.

```r
test_discriminability(player_season_data, "hr", reliability = 0.8, ratio_scale = TRUE)
```

## Setting this up as your team's shared repo

```bash
cd sportmetrics
git init
git add .
git commit -m "Initial commit: redundancy, reliability, discriminability functions"
git remote add origin https://github.com/<your-username>/sportmetrics.git
git branch -M main
git push -u origin main
```

Each sport pair should `git pull` before starting, and can extend these
functions (e.g. a weighted variant of `test_reliability()` for football's
small samples) on a branch, then open a PR back to `main` — so every
sport keeps running the same reviewed implementation instead of drifting
into four different ideas of what "compare" means.

## Data shape notes

- `test_redundancy()` and `test_discriminability()` expect one row per
  player (or player-season) — wide format.
- `test_reliability()` expects one row per player per observation unit
  (one row per plate appearance, per game, per possession) — long format.
  This is the one that needs the most data-wrangling before it's usable;
  budget real time for it, especially for football's small in-season
  samples, where you may need to pool multiple seasons to get enough
  observations per player.
- When you pass a reliability into `test_discriminability()`, it has to match
  the data: same metric, and the same number of observations per player that
  sit behind each value in the wide data frame. A reliability estimated on
  small samples will mis-split signal and noise for full-season values.

## Where this comes from

`test_reliability()` implements a stabilization-style split-half method in
the spirit of Russell Carleton's sabermetric stabilization research and
the FanGraphs Cronbach's-alpha successor to it. Read those before
extending this function — the implementation here is intentionally
simplified for teaching clarity, not a full replication of either.

See `NEWS.md` for what changed between versions.

## A note on how this was built

These functions were drafted by Claude. The test suite passes
(`devtools::test()`) and `devtools::check()` reports no errors, but they
have not yet been run against real sports data. Try each function on a
small real dataset and sanity-check the results before relying on them.
