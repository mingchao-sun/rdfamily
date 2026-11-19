# jamovi analysis class: density (manipulation) test at the cutoff (rddensity).

rddensClass <- R6::R6Class(
    "rddensClass",
    inherit = rddensBase,
    private = list(

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rddens")
            if (is.null(opts$running)) {
                self$results$notes$setContent("<p>Select a running variable to begin.</p>")
                return()
            }
            x <- rd_num(self$data[[opts$running]])
            cc <- opts$cutoff
            if (!is.null(opts$cutVar)) { x <- x - rd_num(self$data[[opts$cutVar]]); cc <- 0 }
            n_na <- sum(is.na(x)); x <- x[!is.na(x)]
            if (!any(x < cc) || !any(x >= cc))
                jmvcore::reject("The running variable needs observations on both sides of the cutoff.")

            args <- list(X = x, c = cc, p = opts$p, kernel = opts$kernel,
                         fitselect = opts$fitselect, vce = opts$vce)
            if (opts$q > 0) args$q <- opts$q
            if (opts$hManual > 0) args$h <- opts$hManual
            d <- rd_guard(suppressWarnings(do.call(rddensity::rddensity, args)))

            jk <- identical(opts$vce, "jackknife")
            tt <- if (jk) d$test$t_jk else d$test$t_asy
            pv <- if (jk) d$test$p_jk else d$test$p_asy
            tb <- self$results$test
            tb$deleteRows()
            tb$addRow(rowKey = 1, values = list(hypothesis = "Density continuous at the cutoff",
                                                t = tt, p = pv))
            tb$setNote("n", sprintf("Variance estimator: %s. A small p-value is evidence of sorting or manipulation around the cutoff.",
                                    if (jk) "jackknife" else "asymptotic plug-in"))

            st <- self$results$sample
            st$deleteRows()
            st$addRow(rowKey = 1, values = list(item = "Observations", left = d$N$left, right = d$N$right))
            st$addRow(rowKey = 2, values = list(item = "Effective observations", left = d$N$eff_left, right = d$N$eff_right))
            st$addRow(rowKey = 3, values = list(item = "Bandwidth", left = d$h$left, right = d$h$right))

            self$results$notes$setContent(
                if (n_na > 0) sprintf("<p>%d observation(s) with missing values were dropped.</p>", n_na) else "")

            if (isTRUE(opts$plot)) {
                pl <- tryCatch(suppressWarnings(suppressMessages(
                    rddensity::rdplotdensity(d, x, noPlot = TRUE))), error = function(e) NULL)
                if (!is.null(pl)) self$results$densPlot$setState(pl$Estplot)
            }
        },

        .plotDens = function(image, ggtheme, theme, ...) {
            if (is.null(image$state)) return(FALSE)
            print(image$state + ggplot2::labs(x = self$options$running, y = "Density") + ggtheme)
            TRUE
        }
    )
)
