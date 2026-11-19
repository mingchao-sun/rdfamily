# jamovi analysis class: RD with multiple cutoffs (rdmulti::rdmc).

rdmcClass <- R6::R6Class(
    "rdmcClass",
    inherit = rdmcBase,
    private = list(

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rdmc")
            if (is.null(opts$outcome) || is.null(opts$running) || is.null(opts$cutVar)) {
                self$results$notes$setContent(
                    "<p>Select an outcome, a running variable (raw score) and a cutoff variable to begin.</p>")
                return()
            }
            df <- data.frame(y = rd_num(self$data[[opts$outcome]]), x = rd_num(self$data[[opts$running]]),
                             cc = rd_num(self$data[[opts$cutVar]]))
            if (!is.null(opts$treatment)) df$d <- rd_num(self$data[[opts$treatment]])
            keep <- stats::complete.cases(df)
            n_drop <- sum(!keep); df <- df[keep, , drop = FALSE]
            cuts <- sort(unique(df$cc))
            if (length(cuts) < 2)
                jmvcore::reject("The cutoff variable has a single value; use the Sharp / Fuzzy / Kink RD analysis instead.")
            if (length(cuts) > 30) jmvcore::reject("More than 30 distinct cutoffs.")

            args <- list(Y = df$y, X = df$x, C = df$cc, pvec = rep(opts$p, length(cuts)),
                         bwselectvec = rep(opts$bwselect, length(cuts)), kernelvec = rep(opts$kernel, length(cuts)),
                         vcevec = rep(opts$vce, length(cuts)), level = opts$level, verbose = FALSE)
            if (!is.null(df$d)) args$fuzzy <- df$d
            utils::capture.output(m <- rd_guard(suppressWarnings(do.call(rdmulti::rdmc, args))))

            labs <- c(rd_fmt(cuts), "Weighted", "Pooled")
            tb <- self$results$est
            tb$deleteRows()
            nc <- length(cuts)
            for (i in seq_len(nc + 2)) {
                tb$addRow(rowKey = i, values = list(
                    label = labs[i], coef = m$Coefs[1, i], bc = m$B[1, i], p = m$Pv[1, i],
                    lo = m$CI[1, i], hi = m$CI[2, i],
                    hl = m$H[1, i], hr = m$H[2, i], nl = m$Nh[1, i], nr = m$Nh[2, i],
                    w = if (i <= nc) m$W[1, i] else NA_real_))
            }
            tb$setNote("n", paste0("Cutoff-specific effects use their own bandwidths. Weighted: average of the cutoff-specific effects ",
                                   "with weights proportional to local sample sizes. Pooled: the running variable is centered at each ",
                                   "cutoff and a single RD is fitted (Cattaneo et al., 2020). Bias-corrected estimates with robust CI."))
            self$results$notes$setContent(
                if (n_drop > 0) sprintf("<p>%d observation(s) with missing values were dropped.</p>", n_drop) else "")

            if (isTRUE(opts$plot))
                self$results$effPlot$setState(data.frame(
                    label = labs, coef = as.numeric(m$B[1, ]), lo = m$CI[1, ], hi = m$CI[2, ],
                    stringsAsFactors = FALSE))
        },

        .plotMc = function(image, ggtheme, theme, ...) {
            if (is.null(image$state)) return(FALSE)
            df <- image$state
            df$label <- factor(df$label, levels = rev(df$label))
            g <- ggplot2::ggplot(df, ggplot2::aes(y = label, x = coef, xmin = lo, xmax = hi)) +
                ggplot2::geom_vline(xintercept = 0, linetype = "dashed") +
                ggplot2::geom_pointrange() +
                ggplot2::labs(y = "Cutoff", x = "Bias-corrected RD estimate (robust CI)")
            print(g + ggtheme)
            TRUE
        }
    )
)
