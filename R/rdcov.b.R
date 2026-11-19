# jamovi analysis class: RD estimates on pre-determined covariates (balance) or placebo outcomes.

rdcovClass <- R6::R6Class(
    "rdcovClass",
    inherit = rdcovBase,
    private = list(

        .init = function() {
            for (v in self$options$covs)
                self$results$balance$addRow(rowKey = v, values = list(label = v))
        },

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rdcov")
            if (length(opts$covs) == 0 || is.null(opts$running)) {
                self$results$notes$setContent(
                    "<p>Select at least one covariate and a running variable to begin.</p>")
                return()
            }
            tb <- self$results$balance
            out <- list(); sds <- numeric(0)
            for (i in seq_along(opts$covs)) {
                v <- opts$covs[i]
                pp <- rd_guard(rd_prepare(self$data, outcome = v, running = opts$running,
                                          cluster = opts$cluster, cutvar = opts$cutVar,
                                          cutoff = opts$cutoff))
                row <- tryCatch({
                    r <- rd_fit(pp, p = opts$p, kernel = opts$kernel, bwselect = opts$bwselect,
                                vce = opts$vce, level = opts$level)
                    rd_row(r, v)
                }, error = function(e) rd_na_row(v))
                out[[i]] <- row
                sds[i] <- stats::sd(pp$df$y)
                tb$setRow(rowKey = v, values = as.list(row))
            }
            res <- do.call(rbind, out)
            self$results$notes$setContent(paste0(
                "<p>Each row is a separate RD regression with the covariate as the outcome and its own MSE/CER-optimal bandwidth. ",
                "Estimate is bias-corrected; s.e., p and CI are robust. Balance is supported when the effects are small and not significant.</p>"))

            std <- res
            std[c("coef", "se", "lo", "hi")] <- res[c("coef", "se", "lo", "hi")] / sds
            self$results$balPlot$setState(std)
        },

        .plotBal = function(image, ggtheme, theme, ...) {
            if (is.null(image$state)) return(FALSE)
            df <- image$state
            df <- df[!is.na(df$coef), , drop = FALSE]
            if (nrow(df) == 0) return(FALSE)
            df$label <- factor(df$label, levels = rev(unique(df$label)))
            g <- ggplot2::ggplot(df, ggplot2::aes(y = label, x = coef, xmin = lo, xmax = hi)) +
                ggplot2::geom_vline(xintercept = 0, linetype = "dashed") +
                ggplot2::geom_pointrange() +
                ggplot2::labs(y = NULL, x = "RD effect in standard deviations of the covariate (robust CI)")
            print(g + ggtheme)
            TRUE
        }
    )
)
