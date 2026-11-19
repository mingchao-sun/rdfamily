# rdpower analysis against the R package rdpower called directly on the same data, and the analysis class on edge cases.
# Needs rdpower in a library named by RD_REFLIB or in the module library. Run from the module root:  Rscript tests/power.R
lib <- Sys.getenv("RD_REFLIB"); if (nzchar(lib)) .libPaths(c(lib, .libPaths()))
suppressMessages({library(jmvcore); library(R6); library(ggplot2)})
if (!requireNamespace("rdpower", quietly = TRUE)) { cat("rdpower is not installed: skipped\n"); quit(status = 0) }
for (f in c("R/00jmv.R", "R/common.R", "R/guide.R", list.files("R", "[.]h[.]R$", full.names = TRUE), list.files("R", "[.]b[.]R$", full.names = TRUE))) source(f)
d <- read.csv("data/rdsenate.csv"); d$tr <- as.numeric(d$margin > 0)
nfail <- 0
ok <- function(cond, msg) { cat(sprintf("[%s] %s\n", if (isTRUE(cond)) "PASS" else "FAIL", msg)); if (!isTRUE(cond)) nfail <<- nfail + 1 }
run <- function(...) { a <- list(...); for (n in setdiff(c("outcome", "running", "treatment", "covs"), names(a))) a[n] <- list(NULL); do.call(rdpower, c(list(data = d), a)) }
cc <- stats::complete.cases(d$vote, d$margin); y <- d$vote[cc]; x <- d$margin[cc]
res <- function(r, tbl, row, col) r[[tbl]]$asDF[row, col]

r <- run(outcome = "vote", running = "margin", mode = "power", tau = 5)
ref <- rdpower::rdpower(data = cbind(y, x), cutoff = 0, tau = 5)
ok(abs(res(r, "res", 1, "rbc") - ref$power.rbc) < 1e-12 && abs(res(r, "res", 1, "conv") - ref$power.conv) < 1e-12, sprintf("power equals the package (%.4f robust, %.4f conventional)", ref$power.rbc, ref$power.conv))
ok(abs(res(r, "res", 2, "rbc") - ref$se.rbc) < 1e-12, "standard error equals the package")
ok(res(r, "design", 1, "left") == ref$N.l && res(r, "design", 2, "right") == ref$Nh.r && abs(res(r, "design", 3, "left") - ref$samph.l) < 1e-12, "observations, effective observations and bandwidth equal the package")
cv <- r$curve$asDF
ok(nrow(cv) == 7 && abs(cv$rbc[1] - 0.05) < 1e-6 && all(diff(cv$rbc) > 0) && abs(cv$rbc[5] - ref$power.rbc) < 1e-12, "power curve: starts at the significance level, rises with the effect, matches the main value at the stated effect")
r2 <- run(outcome = "vote", running = "margin", mode = "mde", beta = 0.8)
ref2 <- rdpower::rdmde(data = cbind(y, x), cutoff = 0, beta = 0.8)
ok(abs(res(r2, "res", 1, "rbc") - ref2$mde) < 1e-12 && abs(res(r2, "res", 1, "conv") - ref2$mde.conv) < 1e-12, sprintf("minimum detectable effect equals the package (%.4f)", ref2$mde))
r3 <- run(outcome = "vote", running = "margin", mode = "sampsi", tau = 5, beta = 0.8)
ref3 <- rdpower::rdsampsi(data = cbind(y, x), cutoff = 0, tau = 5, beta = 0.8)
ok(abs(res(r3, "res", 1, "rbc") - ref3$sampsi.h.tot) < 1e-9 && abs(res(r3, "res", 4, "rbc") - ref3$sampsi.tot) < 1e-9, sprintf("sample size equals the package (%d effective, %d in total)", round(ref3$sampsi.h.tot), round(ref3$sampsi.tot)))
# options passed through: covariates, kernel, order, bandwidth selector, variance, fuzzy
r4 <- run(outcome = "vote", running = "margin", covs = c("termshouse", "population"), mode = "power", tau = 5, kernel = "uniform", p = 2, bwselect = "cerrd", vce = "hc1")
cc2 <- stats::complete.cases(d$vote, d$margin, d$termshouse, d$population)
ref4 <- rdpower::rdpower(data = cbind(d$vote[cc2], d$margin[cc2]), cutoff = 0, tau = 5, covs = as.matrix(d[cc2, c("termshouse", "population")]), kernel = "uniform", p = 2, bwselect = "cerrd", vce = "hc1")
ok(abs(res(r4, "res", 1, "rbc") - ref4$power.rbc) < 1e-12, "covariates, kernel, order, bandwidth selector and variance estimator are passed through")
r5 <- run(outcome = "vote", running = "margin", treatment = "tr", mode = "power", tau = 5)
ref5 <- rdpower::rdpower(data = cbind(y, x), cutoff = 0, tau = 5, fuzzy = d$tr[cc])
ok(abs(res(r5, "res", 1, "rbc") - ref5$power.rbc) < 1e-12, "fuzzy design is passed through")
r6 <- run(outcome = "vote", running = "margin", mode = "power", tau = 5, cutoff = 5)
ok(abs(res(r6, "res", 1, "rbc") - rdpower::rdpower(data = cbind(y, x), cutoff = 5, tau = 5)$power.rbc) < 1e-12, "a cutoff other than zero")
# larger effects give more power, and the sample size reaches the target power
ok(res(run(outcome = "vote", running = "margin", mode = "power", tau = 8), "res", 1, "rbc") > res(r, "res", 1, "rbc"), "a larger effect has more power")
ok(res(run(outcome = "vote", running = "margin", mode = "power", tau = 5, alpha = 0.01), "res", 1, "rbc") < res(r, "res", 1, "rbc"), "a stricter significance level has less power")
# notes, guide, messages
ok(inherits(try(print(run(outcome = "vote", running = "margin", mode = "power", tau = 5, showHelp = TRUE, showGuide = TRUE)), silent = TRUE), "try-error") == FALSE, "notes and guide render")
ok(inherits(try(run(outcome = "vote", running = "margin", mode = "power", tau = 0), silent = TRUE), "try-error"), "an effect of zero is refused")
ok(inherits(try(run(outcome = "vote", running = "vote", mode = "mde"), silent = TRUE), "try-error"), "the same variable twice is refused")
ok(inherits(try(run(outcome = "vote", running = "margin", mode = "power", tau = 5, cutoff = 500), silent = TRUE), "try-error"), "a cutoff outside the data is refused")
ok(inherits(try(print(run(outcome = NULL, running = "margin")), silent = TRUE), "try-error") == FALSE, "no outcome gives a hint")
cat(if (nfail == 0) "\nAll RD power checks passed.\n" else sprintf("\n%d check(s) FAILED.\n", nfail))
if (nfail > 0) quit(status = 1)
