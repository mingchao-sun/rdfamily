# Shared helpers for the RD analyses. Nothing here depends on jamovi, so the
# functions can be tested from a plain R session (see tests/).

rd_num <- function(x) if (is.factor(x)) as.numeric(as.character(x)) else as.numeric(x)

# Parse "a, b, c" into numbers; stop with a readable message on bad input.
rd_parse_list <- function(s, what) {
    v <- trimws(strsplit(if (is.null(s)) "" else s, ",", fixed = TRUE)[[1]])
    v <- v[nzchar(v)]
    out <- suppressWarnings(as.numeric(v))
    if (length(out) == 0 || anyNA(out))
        stop(sprintf("%s: enter numbers separated by commas.", what), call. = FALSE)
    out
}

rd_fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, drop0trailing = TRUE)

# Build the estimation sample. The running variable is centered on a cutoff
# variable when one is given (multiple cutoffs, normalized pooling).
# Rows with a missing value in any used variable are dropped.
rd_prepare <- function(data, outcome = NULL, running, treatment = NULL, covs = NULL,
                       cluster = NULL, cutvar = NULL, cutoff = 0) {
    x <- rd_num(data[[running]])
    cc <- cutoff
    if (!is.null(cutvar)) { x <- x - rd_num(data[[cutvar]]); cc <- 0 }
    df <- data.frame(x = x)
    if (!is.null(outcome)) df$y <- rd_num(data[[outcome]])
    if (!is.null(treatment)) df$d <- rd_num(data[[treatment]])
    if (length(covs) > 0) {
        for (i in seq_along(covs)) df[[paste0("z", i)]] <- rd_num(data[[covs[i]]])
    }
    if (!is.null(cluster)) df$cl <- as.character(data[[cluster]])
    keep <- stats::complete.cases(df)
    n_drop <- sum(!keep)
    df <- df[keep, , drop = FALSE]
    if (nrow(df) < 20) stop("Fewer than 20 complete observations.", call. = FALSE)
    if (!any(df$x < cc) || !any(df$x >= cc))
        stop("The running variable needs observations on both sides of the cutoff.", call. = FALSE)
    zc <- grep("^z[0-9]+$", names(df), value = TRUE)
    list(df = df, c = cc, n_drop = n_drop,
         covs = if (length(zc)) as.matrix(df[, zc, drop = FALSE]) else NULL)
}

# Run rdrobust on a prepared sample. `donut` removes observations closer than
# `donut` to the cutoff. Errors are returned as messages by the caller.
rd_fit <- function(pp, y = NULL, deriv = 0, p = 1, q = 0, h = NULL, b = NULL,
                   kernel = "triangular", bwselect = "mserd", vce = "nn", nnmatch = 3,
                   level = 95, donut = 0, fuzzy = TRUE, use_covs = TRUE, cutoff = NULL) {
    df <- pp$df
    cc <- if (is.null(cutoff)) pp$c else cutoff
    keep <- rep(TRUE, nrow(df))
    if (donut > 0) keep <- abs(df$x - cc) >= donut
    yy <- if (is.null(y)) df$y else y
    args <- list(y = yy[keep], x = df$x[keep], c = cc, deriv = deriv, p = p,
                 kernel = kernel, bwselect = bwselect, vce = vce, level = level)
    if (q > 0) args$q <- q
    if (!is.null(h)) args$h <- h
    if (!is.null(b)) args$b <- b
    if (vce == "nn") args$nnmatch <- nnmatch
    if (fuzzy && !is.null(df$d)) args$fuzzy <- df$d[keep]
    if (use_covs && !is.null(pp$covs)) args$covs <- pp$covs[keep, , drop = FALSE]
    if (!is.null(df$cl)) args$cluster <- df$cl[keep]
    r <- suppressWarnings(do.call(rdrobust::rdrobust, args))
    r$n_donut <- sum(!keep)
    r
}

# Tidy rdrobust output: one row per inference method.
rd_tidy <- function(r) {
    data.frame(method = c("Conventional", "Bias-corrected", "Robust"),
               coef = as.numeric(r$coef), se = as.numeric(r$se), z = as.numeric(r$z),
               p = as.numeric(r$pv), lo = r$ci[, 1], hi = r$ci[, 2],
               stringsAsFactors = FALSE)
}

# One summary row for robustness tables: bias-corrected estimate, robust SE and CI.
rd_row <- function(r, label) {
    data.frame(label = label, coef = as.numeric(r$coef[2]), se = as.numeric(r$se[3]),
               p = as.numeric(r$pv[3]), lo = r$ci[3, 1], hi = r$ci[3, 2],
               hl = r$bws[1, 1], hr = r$bws[1, 2],
               nl = r$N_h[1], nr = r$N_h[2], stringsAsFactors = FALSE)
}

rd_na_row <- function(label)
    data.frame(label = label, coef = NA_real_, se = NA_real_, p = NA_real_, lo = NA_real_,
               hi = NA_real_, hl = NA_real_, hr = NA_real_, nl = NA_integer_, nr = NA_integer_,
               stringsAsFactors = FALSE)

# Turn a fitting error into a jamovi message.
rd_guard <- function(expr) tryCatch(expr, error = function(e) {
    m <- conditionMessage(e)
    if (grepl("Not enough variability|not enough observations|too few", m, ignore.case = TRUE))
        m <- paste0("Too few distinct running-variable values near the cutoff to estimate the model. ",
                    "Check the cutoff, the donut radius, the bandwidth and whether the running variable has few distinct values. (", m, ")")
    else if (grepl("invalid function value|optimize|uniroot|singular|non-finite", m, ignore.case = TRUE))
        m <- paste0("The estimator could not be computed for these data and settings; try a different option ",
                    "(for example another bandwidth criterion or a larger bandwidth). (", m, ")")
    jmvcore::reject(m)
})

# ---- plots -------------------------------------------------------------------

rd_plot_rd <- function(st, xlab, ylab) {
    ggplot2::ggplot() +
        ggplot2::geom_point(data = st$bins, ggplot2::aes(x = x, y = y), alpha = 0.7, size = 1.6) +
        ggplot2::geom_line(data = st$poly, ggplot2::aes(x = x, y = y, group = side), linewidth = 0.9) +
        ggplot2::geom_vline(xintercept = st$c, linetype = "dashed") +
        ggplot2::labs(x = xlab, y = ylab)
}

# Estimates with CIs against a label axis (placebo cutoffs, bandwidths, ...).
rd_plot_est <- function(df, xlab, ref = NULL, numeric_x = FALSE) {
    df <- df[!is.na(df$coef), , drop = FALSE]
    df$lab <- factor(df$label, levels = unique(df$label))
    g <- ggplot2::ggplot(df, ggplot2::aes(x = lab, y = coef, ymin = lo, ymax = hi)) +
        ggplot2::geom_hline(yintercept = 0, colour = "grey50") +
        ggplot2::geom_pointrange() + ggplot2::labs(x = xlab, y = "Estimate (robust CI)")
    if (!is.null(ref) && is.finite(ref)) g <- g + ggplot2::geom_hline(yintercept = ref, linetype = "dashed")
    g
}

# ---- boundary distance (geographic / two-score RD) ---------------------------

# Distance from points (px, py) to the nearest point of a polyline given by vertices (bx, by).
rd_dist_polyline <- function(px, py, bx, by) {
    n <- length(bx)
    if (n < 2) stop("The boundary needs at least two vertices.", call. = FALSE)
    out <- rep(Inf, length(px))
    for (i in seq_len(n - 1)) {
        ax <- bx[i]; ay <- by[i]; vx <- bx[i + 1] - ax; vy <- by[i + 1] - ay
        len2 <- vx^2 + vy^2
        t <- if (len2 > 0) pmin(1, pmax(0, ((px - ax) * vx + (py - ay) * vy) / len2)) else 0
        out <- pmin(out, sqrt((px - (ax + t * vx))^2 + (py - (ay + t * vy))^2))
    }
    out
}

# Signed distance to the boundary of the quadrant {x1 >= c1 & x2 >= c2}: positive inside.
rd_signed_quadrant <- function(x1, x2, c1, c2) {
    inside <- x1 >= c1 & x2 >= c2
    ifelse(inside, pmin(x1 - c1, x2 - c2), -sqrt(pmax(c1 - x1, 0)^2 + pmax(c2 - x2, 0)^2))
}

# Signed distance for a two-score rule. "both": treated if both scores reach their cutoffs;
# "either": treated if at least one does.
rd_signed_twoscore <- function(x1, x2, c1, c2, rule = "both") {
    if (identical(rule, "both")) rd_signed_quadrant(x1, x2, c1, c2)
    else -rd_signed_quadrant(-x1, -x2, -c1, -c2)
}
