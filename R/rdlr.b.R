# jamovi analysis class: local randomization RD inference (rdlocrand).

rdlrClass <- R6::R6Class(
    "rdlrClass",
    inherit = rdlrBase,
    private = list(

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rdlr")
            if (is.null(opts$outcome) || is.null(opts$running)) {
                self$results$notes$setContent("<p>Select an outcome and a running variable to begin.</p>")
                return()
            }
            pp <- rd_guard(rd_prepare(self$data, opts$outcome, opts$running, covs = opts$covs,
                                      cutvar = opts$cutVar, cutoff = opts$cutoff))
            df <- pp$df; cc <- pp$c
            notes <- character(0)
            if (pp$n_drop > 0)
                notes <- c(notes, sprintf("%d observation(s) with missing values were dropped.", pp$n_drop))

            wl <- opts$wLeft; wr <- opts$wRight
            want_win <- identical(opts$windowMode, "auto") || isTRUE(opts$winTable)
            if (want_win) {
                if (is.null(pp$covs))
                    jmvcore::reject("Window selection needs at least one covariate.")
                ws <- rd_guard(suppressWarnings(rdlocrand::rdwinselect(
                    df$x, pp$covs, cutoff = cc, nwindows = opts$nwindows, reps = opts$reps,
                    seed = opts$seed, quietly = TRUE)))
                res <- ws$results
                tb <- self$results$winSel
                tb$deleteRows()
                for (i in seq_len(nrow(res)))
                    tb$addRow(rowKey = i, values = list(w = res[i, "w_right"], minp = res[i, 1],
                                                        bino = res[i, "Bi.test"],
                                                        nl = res[i, "Obs<c"], nr = res[i, "Obs>=c"]))
                tb$setNote("rule", "Recommended window: the largest one whose smallest covariate p-value stays above 0.15.")
                if (identical(opts$windowMode, "auto")) {
                    wl <- cc - ws$w_left; wr <- ws$w_right - cc
                    notes <- c(notes, sprintf("Selected window: [%s, %s].", rd_fmt(ws$w_left), rd_fmt(ws$w_right)))
                }
            }
            if (!(wl > 0 && wr > 0) || !is.finite(wl + wr))
                jmvcore::reject("The window widths must be positive.")
            lo <- cc - wl; hi <- cc + wr

            inw <- df$x >= lo & df$x <= hi
            L <- df$y[inw & df$x < cc]; R <- df$y[inw & df$x >= cc]
            if (length(L) < 3 || length(R) < 3)
                jmvcore::reject("Fewer than three observations on one side of the cutoff in this window.")

            private$.checkpoint()
            ri <- rd_guard(suppressWarnings(rdlocrand::rdrandinf(
                df$y, df$x, cutoff = cc, wl = lo, wr = hi, statistic = opts$statistic,
                p = opts$polyOrder, reps = opts$reps, seed = opts$seed, quietly = TRUE)))

            st <- self$results$sample
            st$deleteRows()
            st$addRow(rowKey = 1, values = list(item = "Window", left = rd_fmt(lo), right = rd_fmt(hi)))
            st$addRow(rowKey = 2, values = list(item = "Observations in window",
                                                left = as.character(length(L)), right = as.character(length(R))))
            st$addRow(rowKey = 3, values = list(item = "Mean outcome",
                                                left = rd_fmt(mean(L)), right = rd_fmt(mean(R))))
            st$addRow(rowKey = 4, values = list(item = "Difference in means",
                                                left = "", right = rd_fmt(mean(R) - mean(L))))

            nm <- c(diffmeans = "Difference in means", ksmirnov = "Kolmogorov-Smirnov",
                    ranksum = "Wilcoxon rank-sum")[[opts$statistic]]
            tb <- self$results$test
            tb$deleteRows()
            tb$addRow(rowKey = 1, values = list(stat = nm, obs = ri$obs.stat,
                                                pfinite = ri$p.value, pasy = ri$asy.pvalue))
            tb$setNote("h0", sprintf(paste0(
                "H0: sharp null of no effect for every unit in the window. %d randomizations (fixed-margins, ",
                "complete randomization). Valid if treatment is as-if random inside the window."), opts$reps))

            self$results$notes$setContent(
                if (length(notes)) paste0("<p>", paste(notes, collapse = "</p><p>"), "</p>") else "")
        }
    )
)
