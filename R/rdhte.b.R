# jamovi analysis class: heterogeneous RD treatment effects (rdhte).
# Nominal moderator: one RD effect per subgroup and a Wald test of equal effects.
# Continuous moderator: effect at moderator = 0 and its linear change per unit.

rdhteClass <- R6::R6Class(
    "rdhteClass",
    inherit = rdhteBase,
    private = list(

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rdhte")
            if (is.null(opts$outcome) || is.null(opts$running) || is.null(opts$hte)) {
                self$results$notes$setContent(
                    "<p>Select an outcome, a running variable and a moderator to begin.</p>")
                return()
            }
            hv <- self$data[[opts$hte]]
            cat_hte <- is.factor(hv)
            df <- data.frame(y = rd_num(self$data[[opts$outcome]]), x = rd_num(self$data[[opts$running]]))
            df$g <- if (cat_hte) as.character(hv) else rd_num(hv)
            if (length(opts$covs) > 0)
                for (i in seq_along(opts$covs)) df[[paste0("z", i)]] <- rd_num(self$data[[opts$covs[i]]])
            if (!is.null(opts$cluster)) df$cl <- as.character(self$data[[opts$cluster]])
            keep <- stats::complete.cases(df)
            n_drop <- sum(!keep); df <- df[keep, , drop = FALSE]
            if (cat_hte) {
                df$g <- factor(df$g)
                if (nlevels(df$g) < 2) jmvcore::reject("The moderator needs at least two groups.")
                if (nlevels(df$g) > 12) jmvcore::reject("More than 12 moderator groups.")
            } else if (stats::sd(df$g) == 0) jmvcore::reject("The moderator is constant.")
            cc <- opts$cutoff
            if (!any(df$x < cc) || !any(df$x >= cc))
                jmvcore::reject("The running variable needs observations on both sides of the cutoff.")

            # rdhte only knows the abbreviations "tri", "epa" and "uni"; any other string silently becomes uniform
            kern <- c(triangular = "tri", epanechnikov = "epa", uniform = "uni")[[opts$kernel]]
            args <- list(y = df$y, x = df$x, c = cc, covs.hte = df$g, p = opts$p, kernel = kern,
                         vce = opts$vce, level = opts$level, bwselect = opts$bwselect, bw.joint = isTRUE(opts$bwJoint))
            if (opts$q > 0) args$q <- opts$q
            zc <- grep("^z[0-9]+$", names(df), value = TRUE)
            if (length(zc)) args$covs.eff <- as.matrix(df[, zc, drop = FALSE])
            if (!is.null(df$cl)) args$cluster <- df$cl
            # Call with variable names, not inlined data: rdhte 0.1.0 deparses its arguments to build names,
            # and do.call() would hand it the whole data vector (error "'names' attribute [...] must be the same length").
            cl <- as.call(c(list(quote(rdhte::rdhte)), stats::setNames(lapply(names(args), as.name), names(args))))
            ev <- list2env(args, parent = environment())
            utils::capture.output(r <- rd_guard(suppressWarnings(eval(cl, ev))))

            k <- length(r$Estimate)
            labs <- if (cat_hte) paste0(opts$hte, " = ", r$W.lev) else
                c(sprintf("Effect at %s = 0", opts$hte), sprintf("Change per unit of %s", opts$hte))
            expand <- function(m) { m <- matrix(m, ncol = 2); if (nrow(m) == 1) m[rep(1, k), , drop = FALSE] else m }
            hm <- expand(r$h); nm <- expand(r$Nh)
            tb <- self$results$est
            tb$deleteRows()
            for (i in seq_len(k)) {
                tb$addRow(rowKey = i, values = list(
                    label = labs[i], coef = unname(r$Estimate[i]), bc = unname(r$Estimate.bc[i]),
                    se = unname(r$se.rb[i]), p = unname(r$pv.rb[i]), lo = r$ci.rb[i, 1], hi = r$ci.rb[i, 2],
                    hl = if (cat_hte) hm[i, 1] else NA_real_, hr = if (cat_hte) hm[i, 2] else NA_real_,
                    nl = if (cat_hte) nm[i, 1] else NA_integer_, nr = if (cat_hte) nm[i, 2] else NA_integer_))
            }
            tb$setNote("n", paste0("Bias-corrected estimates with robust s.e., p and CI. ",
                                   if (cat_hte) "Each row is the RD effect within a subgroup. "
                                   else "The moderator enters linearly; the second row is the interaction. "))

            te <- self$results$test
            te$deleteRows()
            if (cat_hte && k >= 2) {
                Rm <- cbind(-1, diag(k - 1))
                bt <- as.numeric(Rm %*% r$Estimate.bc)
                Vt <- Rm %*% r$vcov %*% t(Rm)
                chi <- as.numeric(t(bt) %*% solve(Vt, bt))
                te$addRow(rowKey = 1, values = list(label = "H0: same RD effect in all subgroups",
                                                    chi = chi, df = k - 1L, p = stats::pchisq(chi, k - 1, lower.tail = FALSE)))
            } else if (!cat_hte) {
                te$addRow(rowKey = 1, values = list(label = "H0: no linear heterogeneity (interaction = 0)",
                                                    chi = unname(r$t.rb[2])^2, df = 1L, p = unname(r$pv.rb[2])))
            }

            self$results$notes$setContent(paste0(
                "<p>Heterogeneity is descriptive: subgroups differ in more than the moderator unless it is randomly assigned. ",
                if (n_drop > 0) sprintf("%d observation(s) with missing values were dropped.", n_drop) else "", "</p>"))

            if (isTRUE(opts$plot) && cat_hte)
                self$results$effPlot$setState(data.frame(label = labs, coef = as.numeric(r$Estimate.bc),
                                                         lo = r$ci.rb[, 1], hi = r$ci.rb[, 2], stringsAsFactors = FALSE))
        },

        .plotHte = function(image, ggtheme, theme, ...) {
            if (is.null(image$state)) return(FALSE)
            df <- image$state
            df$label <- factor(df$label, levels = rev(df$label))
            g <- ggplot2::ggplot(df, ggplot2::aes(y = label, x = coef, xmin = lo, xmax = hi)) +
                ggplot2::geom_vline(xintercept = 0, linetype = "dashed") +
                ggplot2::geom_pointrange() +
                ggplot2::labs(y = NULL, x = "Bias-corrected RD effect (robust CI)")
            print(g + ggtheme)
            TRUE
        }
    )
)
