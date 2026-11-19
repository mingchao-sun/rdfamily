# Builds the example datasets in data/ (real data from CRAN packages; simulated data are marked sim).
suppressMessages({library(RDHonest); library(rdhte); library(rdrobust)})
w <- function(x, f) write.csv(x, file.path("data", f), row.names = FALSE, na = "")
b2n <- function(x) { for (n in names(x)) if (is.logical(x[[n]])) x[[n]] <- as.integer(x[[n]]); x }
w(lee08, "lee08_house.csv")
h <- headst; w(h, "headstart.csv")
w(b2n(rcp), "retirement_food.csv")
w(b2n(rebp), "austria_unemployment.csv")
w(cghs, "uk_school_leaving.csv")
data(rdhte_dataset); w(rdhte_dataset, "rdhte_elections.csv")
set.seed(2026)
# sim multi-cutoff: three states with cutoffs 40, 50, 60; true effect 3
n <- 3000; m <- data.frame(state = sample(c("A", "B", "C"), n, TRUE)); m$cutoff <- c(A = 40, B = 50, C = 60)[m$state]
m$score <- round(runif(n, 20, 80), 2); m$treated <- as.integer(m$score >= m$cutoff)
m$outcome <- round(10 + 0.2 * (m$score - m$cutoff) + 3 * m$treated + rnorm(n, 0, 2), 3); w(m, "sim_multicutoff.csv")
# sim geographic / two-score: treated if both scores >= 0, true effect 2; boundary vertices in bx, by
n <- 3000; g <- data.frame(score1 = round(runif(n, -1, 1), 4), score2 = round(runif(n, -1, 1), 4))
g$treated <- as.integer(g$score1 >= 0 & g$score2 >= 0)
g$outcome <- round(1 + g$score1 + g$score2 + 2 * g$treated + rnorm(n, 0, 0.5), 3)
g$bx <- c(0, 0, 1, rep(NA, n - 3)); g$by <- c(1, 0, 0, rep(NA, n - 3)); w(g, "sim_boundary.csv")
# sim kink: slope changes by 0.5 at 0
n <- 10000; k <- data.frame(x = round(runif(n, -1, 1), 4)); k$y <- round(1 + 0.5 * k$x + 0.5 * pmax(k$x, 0) + rnorm(n, 0, 0.1), 3)
names(k) <- c("running", "outcome"); w(k, "sim_kink.csv")
# sim diff-in-disc, repeated cross-section of units observed twice: pre jump 1, post jump 3
m <- 3000; d <- data.frame(id = rep(1:m, 2), period = rep(0:1, each = m)); x0 <- round(runif(m, -1, 1), 4); d$score <- rep(x0, 2)
d$outcome <- round(0.5 * d$score + (1 + 2 * d$period) * (d$score >= 0) + rnorm(2 * m, 0, 0.5), 3); w(d, "sim_diffindisc.csv")
