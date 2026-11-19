# Headless smoke test: sources the module and runs every analysis on the Senate data.
suppressMessages({library(jmvcore); library(R6); library(ggplot2)})
for (f in c("R/00jmv.R", "R/common.R", "R/guide.R", list.files("R", "[.]h[.]R$", full.names = TRUE),
            list.files("R", "[.]b[.]R$", full.names = TRUE))) source(f)
d <- read.csv("data/rdsenate.csv")
# Headless calls need every optional variable given explicitly (jamovi supplies them itself).
opt <- c("outcome", "running", "treatment", "covs", "cluster", "cutVar", "period", "unit", "x1", "x2", "bx", "by", "hte")
run <- function(fn, d, ...) {
    a <- list(...)
    
    for (n in setdiff(intersect(opt, names(formals(fn))), names(a))) a[n] <- list(NULL)
    print(do.call(fn, c(list(data = d), a)))
}
cat("---- rd (sharp)\n");  run(rd, d, outcome = "vote", running = "margin", plot = FALSE)
cat("---- rd (sharp, covs, cluster)\n"); run(rd, d, outcome = "vote", running = "margin", covs = "termshouse", cluster = "state", plot = FALSE)
cat("---- rd (fuzzy)\n"); d$tr <- as.numeric(d$margin > 0); run(rd, d, outcome = "vote", running = "margin", treatment = "tr", plot = FALSE)
cat("---- rd (kink)\n"); run(rd, d, outcome = "vote", running = "margin", kink = TRUE, plot = FALSE)
cat("---- rddens\n"); run(rddens, d, running = "margin", plot = FALSE)
cat("---- rdcov\n"); run(rdcov, d, covs = c("termshouse", "population", "presdemvoteshlag1"), running = "margin", plot = FALSE)
cat("---- rdsens\n"); run(rdsens, d, outcome = "vote", running = "margin", placeboCheck = TRUE, placeboCuts = "-10,-5,5,10",
   bwCheck = TRUE, donutCheck = TRUE, donutRadii = "0,0.5,1", polyCheck = TRUE)
cat("---- rdpower\n"); for (md in c("power", "mde", "sampsi")) run(rdpower, d, outcome = "vote", running = "margin", mode = md, tau = 5, showHelp = TRUE, showGuide = TRUE)
cat("---- rdlr\n"); run(rdlr, d, outcome = "vote", running = "margin", wLeft = 2, wRight = 2, reps = 500)
cat("---- rdlr auto\n"); run(rdlr, d, outcome = "vote", running = "margin", covs = c("termshouse", "population"), windowMode = "auto", reps = 300)

# ---- additional designs -----------------------------------------------------
set.seed(1)
d$cut <- sample(c(-5, 0, 5), nrow(d), TRUE); d$x2 <- d$margin + d$cut
cat("---- rdmc\n"); run(rdmc, d, outcome = "vote", running = "x2", cutVar = "cut", plot = FALSE)
cat("---- rdhonest\n"); run(rdhonest, d, outcome = "vote", running = "margin")
cat("---- rdhonest (FLCI, M=0.1)\n"); run(rdhonest, d, outcome = "vote", running = "margin", optCriterion = "FLCI", M = 0.1)
# Two-score and polyline boundary on simulated data
n <- 3000; g <- data.frame(s1 = runif(n, -1, 1), s2 = runif(n, -1, 1))
g$t <- as.numeric(g$s1 >= 0 & g$s2 >= 0); g$y <- 1 + g$s1 + g$s2 + 2 * g$t + rnorm(n, 0, 0.5)
g$bx <- c(0, 0, 1, rep(NA, n - 3)); g$by <- c(1, 0, 0, rep(NA, n - 3))
cat("---- rdgeo two-score (true effect 2)\n"); run(rdgeo, g, outcome = "y", x1 = "s1", x2 = "s2", boundary = "both", plot = FALSE)
cat("---- rdgeo polyline (true effect 2)\n"); run(rdgeo, g, outcome = "y", treatment = "t", x1 = "s1", x2 = "s2", bx = "bx", by = "by", plot = FALSE)
# Diff-in-disc: pre jump 1, post jump 3 -> difference 2
m <- 4000; h <- data.frame(x = runif(m, -1, 1), post = rep(0:1, each = m / 2), id = rep(1:(m / 2), 2))
h$x[h$post == 1] <- h$x[h$post == 0]
h$y <- 0.5 * h$x + (1 + 2 * h$post) * (h$x >= 0) + rnorm(m, 0, 0.5)
cat("---- rddid cross-section (diff 2)\n"); run(rddid, h, outcome = "y", running = "x", period = "post")
cat("---- rddid panel (diff 2)\n"); run(rddid, h, outcome = "y", running = "x", period = "post", unit = "id")

d$mid <- factor(d$dmidterm); d$dem <- factor(d$dpresdem)
cat("---- rdhte subgroups\n"); run(rdhte, d, outcome = "vote", running = "margin", hte = "mid")
cat("---- rdhte continuous\n"); run(rdhte, d, outcome = "vote", running = "margin", hte = "termshouse")

# ---- Output section: guide and method notes ---------------------------------
cat("---- guides and notes\n")
for (k in c("rd", "rddens", "rdcov", "rdsens", "rdlr", "rdmc", "rdhonest", "rdgeo", "rddid", "rdhte", "rdcmp"))
    stopifnot(nchar(rd_guide_html(k)) > 200, nchar(rd_notes_html(k)) > 200)
r <- rd(d, outcome = "vote", running = "margin", treatment = NULL, covs = NULL, cluster = NULL, cutVar = NULL,
        plot = FALSE, showHelp = TRUE, showGuide = TRUE)
stopifnot(grepl("US Senate elections", r$guide$content), grepl("Designs", r$helpText$content)); cat("ok\n")

cat("---- rdcmp
"); run(rdcmp, d, outcome = "vote", running = "margin", plot = FALSE)
cat("---- rdcmp fuzzy
"); fz <- read.csv("data/retirement_food.csv"); run(rdcmp, fz, outcome = "food", running = "elig_year", treatment = "retired", plot = FALSE)
cat("---- rdhonest fuzzy\n"); run(rdhonest, fz, outcome = "food", running = "elig_year", treatment = "retired")
g <- rd_guide_html("rd"); stopifnot(grepl("<b>Retirement and food spending (fuzzy)</b>", g, fixed = TRUE), grepl("Data Library", g))
cat(substr(gsub("<[^>]+>", "", rd_guide_html("rddid")), 1, 700), "\n")
