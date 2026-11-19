# jamovi analysis class: sharp / fuzzy / kink regression discontinuity (rdrobust).

rdClass <- R6::R6Class(
    "rdClass",
    inherit = rdBase,
    private = list(

        .init = function() {
            tbl <- self$results$estimates
            for (m in c("Conventional", "Bias-corrected", "Robust"))
                tbl$addRow(rowKey = m, values = list(method = m))
            fs <- self$results$firstStage
            for (m in c("Conventional", "Bias-corrected", "Robust"))
                fs$addRow(rowKey = m, values = list(method = m))
        },

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rd")
            if (is.null(opts$outcome) || is.null(opts$running)) {
                self$results$notes$setContent(
                    "<p>Select an outcome and a running variable to begin.</p>")
                return()
            }
            notes <- character(0)

            pp <- rd_guard(rd_prepare(self$data, opts$outcome, opts$running, opts$treatment,
                                      opts$covs, opts$cluster, opts$cutVar, opts$cutoff))
            if (pp$n_drop > 0)
                notes <- c(notes, sprintf("%d observation(s) with missing values were dropped.", pp$n_drop))
            if (!is.null(opts$cutVar))
                notes <- c(notes, "Multiple cutoffs: the running variable is centered on the cutoff variable and pooled (cutoff = 0).")

            if (anyDuplicated(pp$df$x) && mean(duplicated(pp$df$x)) > 0.2)
                notes <- c(notes, sprintf(paste0("%.0f%% of the running-variable values are repeated (mass points). Continuity-based inference can be ",
                                                 "unreliable with few distinct values; consider the Honest CIs or Local Randomization analyses."),
                                          100 * mean(duplicated(pp$df$x))))
            deriv <- if (isTRUE(opts$kink)) 1 else 0
            p <- opts$p
            if (deriv == 1 && p < 2) {
                p <- 2
                notes <- c(notes, "Kink design: polynomial order raised to 2 (needs p >= deriv + 1). The estimate is the change in the slope at the cutoff.")
            }
            h <- if (opts$hManual > 0) opts$hManual else NULL
            b <- if (opts$hManual > 0 && opts$bManual > 0) opts$bManual else NULL

            fit_args <- list(pp = pp, deriv = deriv, p = p, q = opts$q, h = h, b = b,
                             kernel = opts$kernel, bwselect = opts$bwselect, vce = opts$vce,
                             nnmatch = opts$nnmatch, level = opts$level, donut = opts$donut)
            r <- rd_guard(do.call(rd_fit, fit_args))

            # ---- tables -----------------------------------------------------
            est <- rd_tidy(r)
            tbl <- self$results$estimates
            for (i in 1:3)
                tbl$setRow(rowNo = i, values = as.list(est[i, -1]))
            lab <- if (!is.null(opts$treatment)) "Fuzzy RD (Wald ratio)" else "Sharp RD"
            if (deriv == 1) lab <- paste(lab, "- kink")
            tbl$setNote("design", sprintf(
                "%s. Bias-corrected and Robust use the bias-corrected estimate; Robust adds the variance correction of Calonico et al. (2014). Confidence level %s%%.",
                lab, rd_fmt(opts$level, 1)))

            dt <- self$results$design
            dt$deleteRows()
            two <- function(v, f = function(z) format(z)) c(f(v[1]), f(v[2]))
            rows <- list(
                list("Observations", two(r$N)),
                list("Effective observations (within h)", two(r$N_h)),
                list("Bandwidth h", two(r$bws[1, ], rd_fmt)),
                list("Bandwidth b (bias)", two(r$bws[2, ], rd_fmt)))
            for (i in seq_along(rows))
                dt$addRow(rowKey = i, values = list(item = rows[[i]][[1]],
                                                    left = rows[[i]][[2]][1], right = rows[[i]][[2]][2]))
            dt$setNote("spec", sprintf(
                "Cutoff %s; order p = %d, bias order q = %d; %s kernel; bandwidth: %s; variance: %s%s%s.",
                rd_fmt(pp$c), r$p, r$q, opts$kernel,
                if (!is.null(h)) "manual" else opts$bwselect, opts$vce,
                if (opts$donut > 0) sprintf("; donut radius %s (%d dropped)", rd_fmt(opts$donut), r$n_donut) else "",
                if (!is.null(opts$cluster)) sprintf("; clustered by %s", opts$cluster) else ""))

            if (!is.null(opts$treatment)) {
                fs <- rd_guard(rd_fit(pp, y = pp$df$d, deriv = deriv, p = p, q = opts$q,
                                      h = r$bws[1, ], b = r$bws[2, ], kernel = opts$kernel,
                                      vce = opts$vce, nnmatch = opts$nnmatch, level = opts$level,
                                      donut = opts$donut, fuzzy = FALSE))
                fe <- rd_tidy(fs)
                for (i in 1:3)
                    self$results$firstStage$setRow(rowNo = i, values = as.list(fe[i, c("method", "coef", "se", "p", "lo", "hi")]))
                notes <- c(notes, "Fuzzy design: the weak-instrument risk is small only if the first-stage jump is clearly non-zero.")
            }

            self$results$notes$setContent(
                if (length(notes)) paste0("<p>", paste(notes, collapse = "</p><p>"), "</p>") else "")

            # ---- plot -------------------------------------------------------
            if (isTRUE(opts$plot)) {
                pa <- list(y = pp$df$y, x = pp$df$x, c = pp$c, p = opts$plotOrder,
                           binselect = opts$plotBins, hide = TRUE)
                if (isTRUE(opts$plotWindow)) pa$h <- r$bws[1, ]
                rp <- tryCatch(suppressWarnings(do.call(rdrobust::rdplot, pa)), error = function(e) NULL)
                if (!is.null(rp)) {
                    vb <- rp$vars_bins; vp <- rp$vars_poly
                    self$results$rdPlot$setState(list(
                        bins = data.frame(x = vb$rdplot_mean_x, y = vb$rdplot_mean_y),
                        poly = data.frame(x = vp$rdplot_x, y = vp$rdplot_y, side = vp$rdplot_x >= pp$c),
                        c = pp$c))
                }
            }
        },

        .plotRd = function(image, ggtheme, theme, ...) {
            if (is.null(image$state)) return(FALSE)
            print(rd_plot_rd(image$state, xlab = self$options$running, ylab = self$options$outcome) + ggtheme)
            TRUE
        }
    )
)
