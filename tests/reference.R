# Agreement with the reference packages: the module output must equal a direct call of
# rdrobust / rddensity on the same data and settings. Run from the module folder:
#   Rscript tests/reference.R
suppressMessages({library(jmvcore); library(R6); library(ggplot2)})
for (f in c("R/00jmv.R", "R/common.R", "R/guide.R", list.files("R", "[.]h[.]R$", full.names = TRUE),
            list.files("R", "[.]b[.]R$", full.names = TRUE))) source(f)
opt <- c("outcome", "running", "treatment", "covs", "cluster", "cutVar", "period", "unit", "x1", "x2", "bx", "by", "hte")
run <- function(fn, d, ...) {
    a <- list(...)
    for (n in setdiff(intersect(opt, names(formals(fn))), names(a))) a[n] <- list(NULL)
    do.call(fn, c(list(data = d), a))
}
nfail <- 0
chk <- function(name, got, want, tol = 1e-6) {
    ok <- isTRUE(all(abs(got - want) < tol))
    cat(sprintf("%-46s %s   max |diff| = %.2e\n", name, if (ok) "ok  " else "FAIL", max(abs(got - want))))
    if (!ok) nfail <<- nfail + 1
}
# rdrobust rows: 1 conventional, 2 bias-corrected, 3 robust
cmp_rd <- function(label, tab, rr) {
    chk(paste(label, "coef"), tab$coef, c(rr$coef[1], rr$coef[2], rr$coef[3]))
    chk(paste(label, "se"),   tab$se,   c(rr$se[1],   rr$se[2],   rr$se[3]))
    chk(paste(label, "ci"),   c(tab$lo, tab$hi), c(rr$ci[, 1], rr$ci[, 2]))
}

sen <- read.csv("data/rdsenate.csv")
tab <- function(r) as.data.frame(r$estimates)

# 1. sharp RD, defaults
r1 <- run(rd, sen, outcome = "vote", running = "margin", plot = FALSE)
rr <- rdrobust::rdrobust(sen$vote, sen$margin)
cmp_rd("sharp, defaults", tab(r1), rr)

# 2. sharp RD with covariates, cluster and uniform kernel
r2 <- run(rd, sen, outcome = "vote", running = "margin", covs = "termshouse", cluster = "state",
          kernel = "uniform", plot = FALSE)
rr <- rdrobust::rdrobust(sen$vote, sen$margin, covs = sen$termshouse, cluster = sen$state, kernel = "uniform")
cmp_rd("sharp, covs + cluster + uniform", tab(r2), rr)

# 3. manual bandwidth, quadratic
r3 <- run(rd, sen, outcome = "vote", running = "margin", p = 2, hManual = 12, plot = FALSE)
rr <- rdrobust::rdrobust(sen$vote, sen$margin, p = 2, h = 12)
cmp_rd("sharp, p = 2, h = 12", tab(r3), rr)

# 4. fuzzy RD
fz <- read.csv("data/retirement_food.csv")
r4 <- run(rd, fz, outcome = "food", running = "elig_year", treatment = "retired", plot = FALSE)
rr <- rdrobust::rdrobust(fz$food, fz$elig_year, fuzzy = fz$retired)
cmp_rd("fuzzy", tab(r4), rr)

# 5. kink (deriv = 1)
r5 <- run(rd, sen, outcome = "vote", running = "margin", kink = TRUE, plot = FALSE)
rr <- rdrobust::rdrobust(sen$vote, sen$margin, deriv = 1, p = 2)
cmp_rd("kink", tab(r5), rr)

# 6. density test
r6 <- run(rddens, sen, running = "margin", plot = FALSE)
dd <- rddensity::rddensity(sen$margin)
t6 <- as.data.frame(r6$test)
chk("rddensity robust T", t6$t[1], dd$test$t_jk)
chk("rddensity p-value", t6$p[1], dd$test$p_jk)

cat(if (nfail == 0) "\nAll reference checks passed.\n" else sprintf("\n%d reference check(s) FAILED.\n", nfail))
if (nfail > 0) quit(status = 1)
