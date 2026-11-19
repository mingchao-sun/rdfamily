# jamovi analysis class: RD robustness checks (placebo cutoffs, bandwidth multipliers,
# donut holes, polynomial orders). Each check re-estimates the main specification.

rdsensClass <- R6::R6Class(
    "rdsensClass",
    inherit = rdsensBase,
    private = list(

        .fill = function(tbl, df) {
            tbl$deleteRows()
            for (i in seq_len(nrow(df)))
                tbl$addRow(rowKey = i, values = as.list(df[i, ]))
        },

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rdsens")
            if (is.null(opts$outcome) || is.null(opts$running)) {
                self$results$notes$setContent(
                    "<p>Select an outcome and a running variable to begin.</p>")
                return()
            }
            want <- function(k) isTRUE(opts[[paste0(k, "Check")]]) || isTRUE(opts[[paste0(k, "Fig")]])

            # Parse every list before estimating anything.
            plc <- if (want("placebo")) rd_guard(rd_parse_list(opts$placeboCuts, "Placebo cutoffs")) else NULL
            bwm <- if (want("bw")) rd_guard(rd_parse_list(opts$bwMult, "Bandwidth multipliers")) else NULL
            dnt <- if (want("donut")) rd_guard(rd_parse_list(opts$donutRadii, "Donut radii")) else NULL
            pol <- if (want("poly")) rd_guard(rd_parse_list(opts$polyOrders, "Polynomial orders")) else NULL
            if (!is.null(bwm) && any(bwm <= 0)) jmvcore::reject("Bandwidth multipliers must be positive.")
            if (!is.null(dnt) && any(dnt < 0)) jmvcore::reject("Donut radii must not be negative.")
            if (!is.null(pol) && any(pol < 0 | pol != round(pol))) jmvcore::reject("Polynomial orders must be whole numbers >= 0.")

            pp <- rd_guard(rd_prepare(self$data, opts$outcome, opts$running, opts$treatment,
                                      opts$covs, opts$cluster, opts$cutVar, opts$cutoff))
            upd <- function(a, b) { a[names(b)] <- b; a }   # shallow update (modifyList would merge pp)
            fz <- !is.null(opts$treatment)
            base <- list(pp = pp, p = opts$p, kernel = opts$kernel, bwselect = opts$bwselect,
                         vce = opts$vce, level = opts$level, fuzzy = fz)
            fit <- function(...) do.call(rd_fit, upd(base, list(...)))
            r0 <- rd_guard(fit())
            ref <- rd_row(r0, "Main")
            self$results$notes$setContent(sprintf(paste0(
                "<p>Main estimate (bias-corrected): %s, robust CI [%s, %s]. Each row below re-estimates the model; ",
                "estimates are bias-corrected with robust s.e. and CI. Dashed line in figures = main estimate.</p>"),
                rd_fmt(ref$coef), rd_fmt(ref$lo), rd_fmt(ref$hi)))

            safe <- function(label, expr) { private$.checkpoint(); tryCatch(rd_row(expr, label), error = function(e) rd_na_row(label)) }

            fin <- function(k, rows, xlab) {
                df <- rbind(ref, rows)
                if (isTRUE(opts[[paste0(k, "Check")]])) private$.fill(self$results[[paste0(k, "Table")]], df)
                self$results[[paste0(k, "Plot")]]$setState(list(df = df, ref = ref$coef, xlab = xlab))
            }

            if (!is.null(plc)) {
                rows <- lapply(plc, function(cp) {
                    side <- if (cp < pp$c) pp$df$x < pp$c else pp$df$x >= pp$c
                    sub <- pp
                    sub$df <- pp$df[side, , drop = FALSE]
                    if (!is.null(pp$covs)) sub$covs <- pp$covs[side, , drop = FALSE]
                    sub$c <- cp
                    safe(rd_fmt(cp), do.call(rd_fit, upd(base, list(pp = sub, cutoff = cp, fuzzy = FALSE))))
                })
                fin("placebo", do.call(rbind, rows), "Placebo cutoff")
            }
            if (!is.null(bwm)) {
                rows <- lapply(bwm, function(m)
                    safe(paste0(rd_fmt(m, 2), " x h"),
                         fit(h = r0$bws[1, ] * m, b = r0$bws[2, ] * m)))
                fin("bw", do.call(rbind, rows), "Bandwidth (multiple of optimal)")
            }
            if (!is.null(dnt)) {
                rows <- lapply(dnt, function(d) safe(rd_fmt(d), fit(donut = d)))
                fin("donut", do.call(rbind, rows), "Donut radius")
            }
            if (!is.null(pol)) {
                rows <- lapply(pol, function(pp_) safe(sprintf("p = %d", pp_), fit(p = pp_)))
                fin("poly", do.call(rbind, rows), "Polynomial order")
            }
        },

        .plotEst = function(image) {
            if (is.null(image$state)) return(FALSE)
            print(rd_plot_est(image$state$df, image$state$xlab, ref = image$state$ref) + private$.theme)
            TRUE
        },
        .plotPlacebo = function(image, ggtheme, theme, ...) { private$.theme <- ggtheme; private$.plotEst(image) },
        .plotBw      = function(image, ggtheme, theme, ...) { private$.theme <- ggtheme; private$.plotEst(image) },
        .plotDonut   = function(image, ggtheme, theme, ...) { private$.theme <- ggtheme; private$.plotEst(image) },
        .plotPoly    = function(image, ggtheme, theme, ...) { private$.theme <- ggtheme; private$.plotEst(image) },
        .theme = NULL
    )
)
