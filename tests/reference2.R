# Second set of reference checks: every remaining analysis against an independent computation with the reference
# packages (rdrobust, RDHonest) and brute-force geometry. Run from the module root:  Rscript tests/reference2.R
# Run it with the packages bundled in jamovi too (see PLAN.md): the versions differ from the local library.
suppressMessages({library(jmvcore); library(R6); library(ggplot2)})
for (f in c("R/00jmv.R", "R/common.R", "R/guide.R", list.files("R", "[.]h[.]R$", full.names = TRUE),
            list.files("R", "[.]b[.]R$", full.names = TRUE))) source(f)
opt <- c("outcome", "running", "treatment", "covs", "cluster", "cutVar", "period", "unit", "x1", "x2", "bx", "by", "hte")
run <- function(fn, d, ...) { a <- list(...); for (n in setdiff(intersect(opt, names(formals(fn))), names(a))) a[n] <- list(NULL); do.call(fn, c(list(data = d), a)) }
nfail <- 0
chk <- function(name, got, want, tol = 1e-6) {
    got <- as.numeric(got); want <- as.numeric(want)
    d <- max(abs(got - want))
    ok <- is.finite(d) && d <= tol * max(1, max(abs(want)))
    cat(sprintf("%-58s %s  max |diff| = %.1e\n", name, if (ok) "ok  " else "FAIL", d))
    if (!ok) nfail <<- nfail + 1
}
rr <- function(...) suppressWarnings(rdrobust::rdrobust(...))
bc <- function(r) c(r$coef[2], r$se[3], r$ci[3, 1], r$ci[3, 2])            # bias-corrected estimate, robust s.e. and CI
sen <- read.csv("data/rdsenate.csv"); y <- sen$vote; x <- sen$margin

# ---- rdcov: each covariate as the outcome -------------------------------------------------------------
cv <- c("termshouse", "population", "presdemvoteshlag1")
b <- as.data.frame(run(rdcov, sen, covs = cv, running = "margin", plot = FALSE)$balance)
for (i in seq_along(cv)) {
    ok <- complete.cases(sen[[cv[i]]], x)
    chk(paste("rdcov:", cv[i]), c(b$coef[i], b$se[i], b$lo[i], b$hi[i]), bc(rr(sen[[cv[i]]][ok], x[ok])))
}

# ---- rdsens: placebo cutoffs, bandwidth multipliers, donut holes, polynomial orders --------------------------------
s <- run(rdsens, sen, outcome = "vote", running = "margin", placeboCheck = TRUE, placeboCuts = "-10,-5,5,10",
         bwCheck = TRUE, bwMult = "0.5,1.5,2", donutCheck = TRUE, donutRadii = "0.5,1", polyCheck = TRUE, polyOrders = "2,3")
main <- bc(rr(y, x))
pt <- as.data.frame(s$placeboTable)
chk("rdsens: main row", c(pt$coef[1], pt$se[1]), main[1:2])
for (i in seq_along(c(-10, -5, 5, 10))) {
    cp <- c(-10, -5, 5, 10)[i]; side <- if (cp < 0) x < 0 else x >= 0
    chk(sprintf("rdsens: placebo cutoff %g", cp), c(pt$coef[i + 1], pt$se[i + 1]), bc(rr(y[side], x[side], c = cp))[1:2])
}
r0 <- rr(y, x); bt <- as.data.frame(s$bwTable)
for (i in seq_along(c(0.5, 1.5, 2))) {
    m <- c(0.5, 1.5, 2)[i]
    chk(sprintf("rdsens: bandwidth %g x h", m), c(bt$coef[i + 1], bt$se[i + 1]), bc(rr(y, x, h = r0$bws[1, ] * m, b = r0$bws[2, ] * m))[1:2])
}
dt <- as.data.frame(s$donutTable)
for (i in seq_along(c(0.5, 1))) {
    dd <- c(0.5, 1)[i]; keep <- abs(x - 0) >= dd
    chk(sprintf("rdsens: donut radius %g", dd), c(dt$coef[i + 1], dt$se[i + 1]), bc(rr(y[keep], x[keep]))[1:2])
}
po <- as.data.frame(s$polyTable)
for (i in seq_along(c(2, 3)))
    chk(sprintf("rdsens: polynomial order %d", c(2, 3)[i]), c(po$coef[i + 1], po$se[i + 1]), bc(rr(y, x, p = c(2, 3)[i]))[1:2])

# ---- rdcmp: alternative specifications -----------------------------------------------------------------------------
cm <- as.data.frame(run(rdcmp, sen, outcome = "vote", running = "margin", plot = FALSE, cmpBw = TRUE, cmpKernel = TRUE, cmpOrder = TRUE,
                        cmpHonest = TRUE, cmpLocrand = FALSE)$cmp)
spec <- list(Main = list(), `MSE, different bandwidth each side` = list(bwselect = "msetwo"), `CER-optimal bandwidth` = list(bwselect = "cerrd"),
             `CER, different bandwidth each side` = list(bwselect = "certwo"), `MSE, median of selectors` = list(bwselect = "msecomb2"),
             `Epanechnikov kernel` = list(kernel = "epanechnikov"), `Uniform kernel` = list(kernel = "uniform"), `Local quadratic` = list(p = 2))
for (nm in names(spec)) {
    row <- if (nm == "Main") cm[cm$group == "Main", ][1, ] else cm[grepl(nm, cm$label, fixed = TRUE), ][1, ]
    want <- bc(do.call(rr, c(list(y, x), spec[[nm]])))
    chk(paste("rdcmp:", nm), c(row$coef, row$se, row$lo, row$hi), want)
}
hn <- suppressMessages(suppressWarnings(RDHonest::RDHonest(y ~ x, data = data.frame(y = y, x = x), cutoff = 0)))$coefficients
row <- cm[cm$group == "Honest", ][1, ]
chk("rdcmp: honest row", c(row$coef, row$se, row$lo, row$hi), c(hn$estimate, hn$std.error, hn$conf.low, hn$conf.high))

# ---- rdhonest: options reach the package ---------------------------------------------------------------------------------
hd <- data.frame(y = y, x = x)
hon <- function(...) suppressMessages(suppressWarnings(RDHonest::RDHonest(y ~ x, data = hd, ...)))$coefficients
for (case in list(list(label = "default", mod = list(), pk = list()),
                  list(label = "uniform kernel", mod = list(kernel = "uniform"), pk = list(kern = "uniform")),
                  list(label = "Epanechnikov kernel", mod = list(kernel = "epanechnikov"), pk = list(kern = "epanechnikov")),
                  list(label = "FLCI criterion", mod = list(optCriterion = "FLCI"), pk = list(opt.criterion = "FLCI")),
                  list(label = "EHW standard errors", mod = list(seMethod = "EHW"), pk = list(se.method = "EHW")),
                  list(label = "M = 0.1", mod = list(M = 0.1), pk = list(M = 0.1)),
                  list(label = "bandwidth 5", mod = list(hManual = 5), pk = list(h = 5)))) {
    got <- as.data.frame(do.call(run, c(list(rdhonest, sen, outcome = "vote", running = "margin"), case$mod))$est)
    want <- do.call(hon, case$pk)
    chk(paste("rdhonest:", case$label), c(got$coef, got$se, got$lo, got$hi), c(want$estimate, want$std.error, want$conf.low, want$conf.high))
}
# the options must change the answer (guards against an option that is silently ignored)
g1 <- as.data.frame(run(rdhonest, sen, outcome = "vote", running = "margin")$est)$coef
g2 <- as.data.frame(run(rdhonest, sen, outcome = "vote", running = "margin", kernel = "uniform")$est)$coef
cat(sprintf("%-58s %s\n", "rdhonest: uniform kernel changes the estimate", if (abs(g1 - g2) > 0.1) "ok  " else "FAIL")); if (abs(g1 - g2) <= 0.1) nfail <- nfail + 1

# ---- rddid: repeated cross-sections and panel -------------------------------------------------------------------------------
au <- read.csv("data/austria_unemployment.csv")
dd <- as.data.frame(run(rddid, au, outcome = "duration", running = "age", period = "period", cutoff = 50)$est)
pre <- au[au$period == 0, ]; pst <- au[au$period == 1, ]
a <- rr(pst$duration, pst$age, c = 50); b0 <- rr(pre$duration, pre$age, c = 50)
hh <- colMeans(rbind(a$bws[1, ], b0$bws[1, ])); bb <- colMeans(rbind(a$bws[2, ], b0$bws[2, ]))
r1 <- rr(pst$duration, pst$age, c = 50, h = hh, b = bb); r0 <- rr(pre$duration, pre$age, c = 50, h = hh, b = bb)
chk("rddid cross-sections: before and after rows", c(dd$coef[1], dd$coef[2], dd$se[1], dd$se[2]), c(r0$coef[2], r1$coef[2], r0$se[3], r1$se[3]))
chk("rddid cross-sections: difference and s.e.", c(dd$coef[3], dd$se[3]), c(r1$coef[2] - r0$coef[2], sqrt(r1$se[3]^2 + r0$se[3]^2)))
sd <- read.csv("data/sim_diffindisc.csv")
pp <- as.data.frame(run(rddid, sd, outcome = "outcome", running = "score", period = "period", unit = "id")$est)
w0 <- sd[sd$period == 0, ]; w1 <- sd[sd$period == 1, ]; m <- merge(w0, w1, by = "id", suffixes = c(".0", ".1"))
rp <- rr(m$outcome.1 - m$outcome.0, m$score.1, c = 0)
chk("rddid panel: RD on the change in the outcome", c(pp$coef[1], pp$se[1]), c(rp$coef[2], rp$se[3]))

# ---- rdgeo: brute-force distance to the boundary --------------------------------------------------------------------------------
bg <- read.csv("data/sim_boundary.csv")
brute <- function(px, py, segs, n = 4000) {
    out <- rep(Inf, length(px))
    for (s in segs) {
        t <- seq(0, 1, length.out = n); sx <- s[1] + t * (s[3] - s[1]); sy <- s[2] + t * (s[4] - s[2])
        out <- pmin(out, vapply(seq_along(px), function(i) sqrt(min((px[i] - sx)^2 + (py[i] - sy)^2)), 0))
    }
    out
}
sub <- bg[seq(1, nrow(bg), by = 10), ]                                  # 300 points keep the brute force quick
bnd <- bg[!is.na(bg$bx) & !is.na(bg$by), c("bx", "by")]
segs <- lapply(seq_len(nrow(bnd) - 1), function(i) c(bnd$bx[i], bnd$by[i], bnd$bx[i + 1], bnd$by[i + 1]))
chk("rdgeo: distance to a polyline (brute force)", rd_dist_polyline(sub$score1, sub$score2, bnd$bx, bnd$by), brute(sub$score1, sub$score2, segs), 2e-3)
qd <- rd_signed_twoscore(sub$score1, sub$score2, 0, 0, "both")
bq <- brute(sub$score1, sub$score2, list(c(0, 0, 4, 0), c(0, 0, 0, 4)))
chk("rdgeo: both-scores rule, absolute distance", abs(qd), bq, 2e-3)
chk("rdgeo: both-scores rule, sign", sign(qd), ifelse(sub$score1 >= 0 & sub$score2 >= 0, 1, -1))
ed <- rd_signed_twoscore(sub$score1, sub$score2, 0, 0, "either")
be <- brute(sub$score1, sub$score2, list(c(0, 0, -4, 0), c(0, 0, 0, -4)))
chk("rdgeo: either-score rule, absolute distance", abs(ed), be, 2e-3)
chk("rdgeo: either-score rule, sign", sign(ed), ifelse(sub$score1 >= 0 | sub$score2 >= 0, 1, -1))
gm <- as.data.frame(run(rdgeo, bg, outcome = "outcome", x1 = "score1", x2 = "score2", boundary = "both", plot = FALSE)$est)
dist <- rd_signed_twoscore(bg$score1, bg$score2, 0, 0, "both")
chk("rdgeo: two-score RD equals rdrobust on the signed distance", c(gm$coef[2], gm$se[3]), c(rr(bg$outcome, dist)$coef[2], rr(bg$outcome, dist)$se[3]))

cat(if (nfail == 0) "\nAll rdfamily reference checks (second set) passed.\n" else sprintf("\n%d check(s) FAILED.\n", nfail))
if (nfail > 0) quit(status = 1)
