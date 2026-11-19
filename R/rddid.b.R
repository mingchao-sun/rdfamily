# jamovi analysis class: RD difference-in-discontinuities (RD before vs after a second policy change).
# Repeated cross-sections: RD estimated in each period with a common bandwidth, difference of the
# bias-corrected estimates, independent-sample standard error. Panel (unit id given): RD on the
# unit-level change in the outcome.

rddidClass <- R6::R6Class(
    "rddidClass",
    inherit = rddidBase,
    private = list(

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rddid")
            if (is.null(opts$outcome) || is.null(opts$running) || is.null(opts$period)) {
                self$results$notes$setContent(
                    "<p>Select an outcome, a running variable and a period variable (two values) to begin.</p>")
                return()
            }
            df <- data.frame(y = rd_num(self$data[[opts$outcome]]), x = rd_num(self$data[[opts$running]]),
                             per = as.character(self$data[[opts$period]]))
            if (!is.null(opts$unit)) df$u <- as.character(self$data[[opts$unit]])
            df <- df[stats::complete.cases(df), , drop = FALSE]
            vals <- sort(unique(rd_num_or_chr(self$data[[opts$period]])))
            vals <- as.character(vals[!is.na(vals)])
            if (length(vals) != 2) jmvcore::reject("The period variable must have exactly two values.")
            df$post <- df$per == vals[2]
            cc <- opts$cutoff
            base <- list(p = opts$p, kernel = opts$kernel, bwselect = opts$bwselect, vce = opts$vce, level = opts$level)
            fit <- function(sub, ...) rd_guard(do.call(rd_fit, c(list(pp = list(df = sub, c = cc, covs = NULL)), list(...), base)))
            z <- stats::qnorm(1 - (1 - opts$level / 100) / 2)
            tb <- self$results$est; tb$deleteRows()
            ds <- self$results$design; ds$deleteRows()
            addrow <- function(i, row) tb$addRow(rowKey = i, values = as.list(row[c("label", "coef", "se", "p", "lo", "hi")]))
            add_ds <- function(i, a, b) ds$addRow(rowKey = i, values = list(item = a, value = b))

            if (!is.null(opts$unit)) {
                if (anyDuplicated(df[, c("u", "post")]))
                    jmvcore::reject("Each unit may appear only once per period; the unit variable has repeated rows within a period.")
                w <- stats::reshape(df[, c("u", "post", "y", "x")], idvar = "u", timevar = "post", direction = "wide")
                w <- w[stats::complete.cases(w[, c("y.TRUE", "y.FALSE")]), , drop = FALSE]
                if (nrow(w) < 20) jmvcore::reject("Fewer than 20 units are observed in both periods.")
                sub <- data.frame(y = w$y.TRUE - w$y.FALSE, x = w$x.TRUE)
                if (any(abs(w$x.TRUE - w$x.FALSE) > 1e-8, na.rm = TRUE))
                    jmvcore::reject("The running variable must be the same in both periods for each unit (panel differencing).")
                rd <- fit(sub)
                addrow(1, rd_row(rd, "Difference (RD on the change in the outcome)"))
                add_ds(1, "Units in both periods", as.character(nrow(w)))
                add_ds(2, "Bandwidth h", rd_fmt(rd$bws[1, 1]))
                add_ds(3, "Effective observations (left / right)", paste(rd$N_h, collapse = " / "))
                msg <- "Panel mode: the outcome is differenced within unit before the RD, which removes unit fixed effects."
            } else {
                pre <- df[!df$post, , drop = FALSE]; pst <- df[df$post, , drop = FALSE]
                r1 <- fit(pst)
                hh <- colMeans(rbind(r1$bws[1, ], fit(pre)$bws[1, ]))
                bb <- colMeans(rbind(r1$bws[2, ], fit(pre)$bws[2, ]))
                r0 <- fit(pre, h = hh, b = bb); r1 <- fit(pst, h = hh, b = bb)
                a0 <- rd_row(r0, paste("Before:", vals[1])); a1 <- rd_row(r1, paste("After:", vals[2]))
                dd <- a1$coef - a0$coef; se <- sqrt(a1$se^2 + a0$se^2)
                diff <- data.frame(label = "Difference (after - before)", coef = dd, se = se,
                                   p = 2 * stats::pnorm(-abs(dd / se)), lo = dd - z * se, hi = dd + z * se)
                addrow(1, a0); addrow(2, a1); addrow(3, diff)
                add_ds(1, "Common bandwidth h", rd_fmt(hh[1]))
                add_ds(2, "Observations before (left / right)", paste(r0$N_h, collapse = " / "))
                add_ds(3, "Observations after (left / right)", paste(r1$N_h, collapse = " / "))
                msg <- paste0("Repeated cross-sections: the RD is estimated in each period with the same bandwidth (average of the two ",
                              "MSE-optimal ones); samples are treated as independent. The difference removes a discontinuity that ",
                              "existed before the policy change.")
            }
            self$results$notes$setContent(paste0("<p>", msg, " Estimates are bias-corrected with robust s.e. and CI.</p>"))
        }
    )
)

# Sorting helper: numeric order when the period variable is numeric, otherwise alphabetical.
rd_num_or_chr <- function(x) {
    if (is.factor(x)) { n <- suppressWarnings(as.numeric(as.character(x))); if (!anyNA(n[!is.na(x)])) return(n); return(as.character(x)) }
    x
}
