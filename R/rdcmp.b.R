# jamovi analysis class: side-by-side comparison of RD methods and specifications on the same data.
# The first row is the main specification (rdrobust: local linear, triangular kernel, MSE-optimal
# bandwidth, nearest-neighbor variance). Rows are not ranked and nothing is marked as "best".

rdcmpClass <- R6::R6Class(
    "rdcmpClass",
    inherit = rdcmpBase,
    private = list(

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rdcmp")
            if (is.null(opts$outcome) || is.null(opts$running)) {
                self$results$notes$setContent("<p>Select an outcome and a running variable to begin.</p>")
                return()
            }
            pp <- rd_guard(rd_prepare(self$data, opts$outcome, opts$running, opts$treatment,
                                      opts$covs, opts$cluster, NULL, opts$cutoff))
            fz <- !is.null(opts$treatment)
            lev <- opts$level
            rows <- list()
            add <- function(group, label, coef, se, p, lo, hi, h, n)
                rows[[length(rows) + 1]] <<- data.frame(group = group, label = label, coef = coef, se = se, p = p,
                                                        lo = lo, hi = hi, h = h, n = n, stringsAsFactors = FALSE)
            fmt_h <- function(r) if (r$bws[1, 1] == r$bws[1, 2]) rd_fmt(r$bws[1, 1]) else
                paste(rd_fmt(r$bws[1, 1]), "/", rd_fmt(r$bws[1, 2]))
            add_rd <- function(group, label, ...) {
                private$.checkpoint()
                r <- tryCatch(rd_fit(pp, level = lev, ...), error = function(e) NULL)
                if (is.null(r)) { add(group, label, NA, NA, NA, NA, NA, "", ""); return(NULL) }
                add(group, label, r$coef[2], r$se[3], r$pv[3], r$ci[3, 1], r$ci[3, 2], fmt_h(r),
                    paste(r$N_h, collapse = " / "))
                r
            }
            base <- list(p = 1, kernel = "triangular", bwselect = "mserd", vce = "nn")
            main <- do.call(add_rd, c(list("Main", "Local linear, triangular, MSE bandwidth"), base[c("p", "kernel", "bwselect", "vce")]))
            if (is.null(main)) jmvcore::reject("The main specification could not be estimated.")

            if (isTRUE(opts$cmpBw)) {
                for (b in c("msetwo", "cerrd", "certwo", "msecomb2"))
                    add_rd("Bandwidth", c(msetwo = "MSE, different bandwidth each side", cerrd = "CER-optimal bandwidth",
                                          certwo = "CER, different bandwidth each side", msecomb2 = "MSE, median of selectors")[[b]],
                           p = 1, kernel = "triangular", bwselect = b, vce = "nn")
            }
            if (isTRUE(opts$cmpKernel)) {
                add_rd("Kernel", "Epanechnikov kernel", p = 1, kernel = "epanechnikov", bwselect = "mserd", vce = "nn")
                add_rd("Kernel", "Uniform kernel", p = 1, kernel = "uniform", bwselect = "mserd", vce = "nn")
            }
            if (isTRUE(opts$cmpOrder))
                add_rd("Order", "Local quadratic", p = 2, kernel = "triangular", bwselect = "mserd", vce = "nn")

            if (isTRUE(opts$cmpHonest)) {
                private$.checkpoint()
                df <- data.frame(y = pp$df$y, x = pp$df$x)
                if (fz) df$d <- pp$df$d
                hn <- tryCatch(suppressMessages(suppressWarnings(RDHonest::RDHonest(
                    if (fz) y | d ~ x else y ~ x, data = df, cutoff = pp$c, alpha = 1 - lev / 100)))$coefficients,
                    error = function(e) NULL)
                if (is.null(hn)) add("Honest", "Honest CI (MSE bandwidth, rule-of-thumb M)", NA, NA, NA, NA, NA, "", "")
                else add("Honest", "Honest CI (MSE bandwidth, rule-of-thumb M)", hn$estimate, hn$std.error, hn$p.value,
                         hn$conf.low, hn$conf.high, rd_fmt(hn$bandwidth), rd_fmt(hn$eff.obs, 0))
            }
            note_lr <- ""
            if (isTRUE(opts$cmpLocrand)) {
                if (fz) {
                    note_lr <- " Local randomization is skipped for fuzzy designs."
                } else {
                    w <- if (opts$wLocrand > 0) opts$wLocrand else main$bws[1, 1]
                    lo <- pp$c - w; hi <- pp$c + w
                    inw <- pp$df$x >= lo & pp$df$x <= hi
                    L <- pp$df$y[inw & pp$df$x < pp$c]; R <- pp$df$y[inw & pp$df$x >= pp$c]
                    if (length(L) >= 3 && length(R) >= 3) {
                        ri <- tryCatch(suppressWarnings(rdlocrand::rdrandinf(
                            pp$df$y, pp$df$x, cutoff = pp$c, wl = lo, wr = hi, reps = opts$reps, seed = opts$seed,
                            quietly = TRUE)), error = function(e) NULL)
                        add("Local randomization", "Difference in means in the window", mean(R) - mean(L), NA,
                            if (is.null(ri)) NA else ri$p.value, NA, NA, paste0("±", rd_fmt(w)),
                            paste(length(L), "/", length(R)))
                        note_lr <- " Local randomization reports the permutation p-value only (no standard error or interval)."
                    } else note_lr <- " Local randomization skipped: too few observations in the window."
                }
            }

            res <- do.call(rbind, rows)
            tb <- self$results$cmp
            tb$deleteRows()
            for (i in seq_len(nrow(res))) tb$addRow(rowKey = i, values = as.list(res[i, ]))
            tb$setNote("n", paste0("Estimates are bias-corrected with robust s.e. and CI (rdrobust rows); the honest row uses the Armstrong-Kolesar ",
                                   "worst-case bias bound. Rows are different ways of estimating the same effect and are not ranked; ",
                                   "decide on the specification before looking at the results."))
            self$results$notes$setContent(paste0(
                "<p>Main specification: local linear, triangular kernel, MSE-optimal bandwidth.", note_lr,
                if (pp$n_drop > 0) sprintf(" %d observation(s) with missing values were dropped.", pp$n_drop) else "", "</p>"))
            self$results$cmpPlot$setState(list(df = res, ref = res$coef[1]))
        },

        .plotCmp = function(image, ggtheme, theme, ...) {
            if (is.null(image$state)) return(FALSE)
            df <- image$state$df
            df <- df[!is.na(df$coef), , drop = FALSE]
            df$lab <- factor(df$label, levels = rev(unique(df$label)))
            g <- ggplot2::ggplot(df, ggplot2::aes(y = lab, x = coef, xmin = lo, xmax = hi, colour = group)) +
                ggplot2::geom_vline(xintercept = 0, linetype = "dotted") +
                ggplot2::geom_vline(xintercept = image$state$ref, linetype = "dashed") +
                ggplot2::geom_pointrange(na.rm = TRUE) +
                ggplot2::labs(y = NULL, x = "RD estimate (CI)", colour = NULL)
            print(g + ggtheme)
            TRUE
        }
    )
)
