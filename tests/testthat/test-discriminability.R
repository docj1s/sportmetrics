test_that("test_discriminability reports observed spread without cv by default", {
  set.seed(1)
  df <- data.frame(metric = rnorm(200, mean = 50, sd = 12))
  result <- suppressMessages(test_discriminability(df, "metric"))

  expect_equal(result$mean, mean(df$metric))
  expect_equal(result$sd, stats::sd(df$metric))
  expect_equal(result$range, range(df$metric))
  expect_null(result$cv)
  expect_null(result$true_sd)
})

test_that("test_discriminability says so when no reliability is supplied", {
  df <- data.frame(metric = c(1, 2, 3, 4))
  expect_message(test_discriminability(df, "metric"), "reliability")
})

test_that("cv flags low spread when ratio_scale = TRUE", {
  set.seed(1)
  df <- data.frame(metric = rnorm(200, mean = 50, sd = 0.5))
  result <- suppressMessages(test_discriminability(df, "metric", ratio_scale = TRUE))
  expect_lt(result$cv, 0.05)
})

test_that("cv flags high spread when ratio_scale = TRUE", {
  set.seed(1)
  df <- data.frame(metric = rnorm(200, mean = 50, sd = 12))
  result <- suppressMessages(test_discriminability(df, "metric", ratio_scale = TRUE))
  expect_gt(result$cv, 0.2)
})

test_that("ratio_scale = TRUE refuses metrics with negative values", {
  df <- data.frame(wpa = c(1.8, -0.6, 0.3, -1.2, 0.2))
  expect_error(test_discriminability(df, "wpa", ratio_scale = TRUE), "negative")
})

test_that("ratio_scale = TRUE refuses a metric whose mean is zero", {
  df <- data.frame(metric = c(0, 0, 0, 0))
  expect_error(test_discriminability(df, "metric", ratio_scale = TRUE), "undefined")
})

test_that("ratio_scale must be TRUE or FALSE", {
  df <- data.frame(metric = c(1, 2, 3))
  expect_error(test_discriminability(df, "metric", ratio_scale = "yes"), "TRUE or FALSE")
  expect_error(test_discriminability(df, "metric", ratio_scale = NA), "TRUE or FALSE")
})

test_that("spread statistics are unchanged when the zero point moves", {
  # Regression test for the cv problem: same players, zero moved by 0.2
  df <- data.frame(wpa = c(1.8, -0.6, 0.3, -1.2, 0.2))
  df$wpa_shifted <- df$wpa - 0.2

  a <- test_discriminability(df, "wpa", reliability = 0.7)
  b <- test_discriminability(df, "wpa_shifted", reliability = 0.7)

  expect_equal(a$sd, 1.131371, tolerance = 1e-6)
  expect_equal(a$sd, b$sd)
  expect_equal(a$true_sd, b$true_sd)
  expect_equal(a$noise_sd, b$noise_sd)
  expect_equal(a$signal_to_noise, b$signal_to_noise)
  expect_null(a$cv)
  expect_null(b$cv)
})

test_that("test_discriminability decomposes signal vs noise when reliability given", {
  set.seed(1)
  df <- data.frame(metric = rnorm(200, mean = 10, sd = 2))
  result <- test_discriminability(df, "metric", reliability = 0.7)

  expect_equal(result$reliability, 0.7)
  expect_lt(result$true_sd, result$sd)
  expect_equal(result$true_sd^2 + result$noise_sd^2, result$sd^2)
  expect_equal(result$signal_to_noise, sqrt(0.7 / 0.3))
})

test_that("reliability of 0 and 1 give the boundary cases", {
  df <- data.frame(metric = c(1, 2, 3, 4, 5))

  perfect <- test_discriminability(df, "metric", reliability = 1)
  expect_equal(perfect$noise_sd, 0)
  expect_equal(perfect$true_sd, perfect$sd)
  expect_equal(perfect$signal_to_noise, Inf)

  none <- test_discriminability(df, "metric", reliability = 0)
  expect_equal(none$true_sd, 0)
  expect_equal(none$signal_to_noise, 0)
})

test_that("test_discriminability validates reliability", {
  df <- data.frame(metric = c(1, 2, 3, 4, 5))
  expect_error(test_discriminability(df, "metric", reliability = 1.2), "between 0 and 1")
  expect_error(test_discriminability(df, "metric", reliability = -0.1), "between 0 and 1")
  expect_error(test_discriminability(df, "metric", reliability = c(0.5, 0.6)), "between 0 and 1")
})

test_that("test_discriminability errors on missing column", {
  df <- data.frame(a = 1:5)
  expect_error(test_discriminability(df, "b"), "not found")
})
