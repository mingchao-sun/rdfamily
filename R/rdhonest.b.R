# jamovi analysis class: honest RD confidence intervals (RDHonest; Armstrong and Kolesar, 2020).

rdhonestClass <- R6::R6Class(
    "rdhonestClass",
    inherit = rdhonestBase,
    private = list(

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rdhonest")
            if (is.null(opts$outcome) || is.null(opts$running)) {
                self$results$notes$setContent("<p>Select an outcome and a running variable to begin.</p>")
                return()
            }
            df <- data.frame(y = rd_num(self$data[[opts$outcome]]), x = rd_num(self$data[[opts$running]]))
            fz <- !is.null(opts$treatment)
            if (fz) df$d <- rd_num(self$data[[opts$treatment]])
            keep <- stats::complete.cases(df)
            n_drop <- sum(!keep); df <- df[keep, , drop = FALSE]
            if (!any(df$x < opts$cutoff) || !any(df$x >= opts$cutoff))
                jmvcore::reject("The running variable needs observations on both sides of the cutoff.")

            args <- list(formula = if (fz) y | d ~ x else y ~ x, data = df, cutoff = opts$cutoff,
                         kern = opts$kernel, opt.criterion = opts$optCriterion,
                         se.method = opts$seMethod, alpha = 1 - opts$level / 100)
            if (opts$M > 0) args$M <- if (fz) rep(opts$M, 2) else opts$M
            if (opts$hManual > 0) args$h <- opts$hManual
            h <- rd_guard(suppressMessages(suppressWarnings(do.call(RDHonest::RDHonest, args))))
            co <- h$coefficients

            tb <- self$results$est
            tb$deleteRows()
            tb$addRow(rowKey = 1, values = list(
                what = if (fz) "Fuzzy RD parameter" else "Sharp RD parameter",
                coef = co$estimate, se = co$std.error, bias = co$maximum.bias,
                lo = co$conf.low, hi = co$conf.high, p = co$p.value))
            tb$setNote("n", sprintf(paste0("Honest CI at level %s%%: uses the worst-case bias given the smoothness bound M, so it has ",
                                           "correct coverage without undersmoothing or bias-correction."), rd_fmt(opts$level, 1)))

            sp <- self$results$spec
            sp$deleteRows()
            rows <- list(c("Bandwidth", rd_fmt(co$bandwidth)), c("Effective observations", rd_fmt(co$eff.obs, 0)),
                         if (fz) c("Smoothness bounds M (reduced form / first stage)", paste0(rd_fmt(co$M.rf, 4), " / ", rd_fmt(co$M.fs, 4), if (opts$M > 0) "" else " (rule of thumb)"))
                         else c("Smoothness bound M", paste0(rd_fmt(co$M, 4), if (opts$M > 0) "" else " (rule of thumb)")),
                         c("Kernel", opts$kernel), c("Bandwidth criterion", opts$optCriterion))
            for (i in seq_along(rows))
                sp$addRow(rowKey = i, values = list(item = rows[[i]][1], value = rows[[i]][2]))

            self$results$notes$setContent(
                if (n_drop > 0) sprintf("<p>%d observation(s) with missing values were dropped.</p>", n_drop) else "")
        }
    )
)
