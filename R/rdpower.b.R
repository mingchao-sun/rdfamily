# jamovi analysis class: power, minimum detectable effect and sample size of a regression discontinuity design (rdpower).

rdpowerClass <- R6::R6Class(
    "rdpowerClass",
    inherit = rdpowerBase,
    private = list(

        .run = function() {
            o <- self$options
            rd_show_text(self$results, o, "rdpower")
            if (is.null(o$outcome) || is.null(o$running)) {
                self$results$notes$setContent("<p>Select an outcome and a running variable to begin. The power calculation uses the data to estimate the variance, the bias and the bandwidth around the cutoff.</p>")
                for (nm in c("design", "res", "curve")) self$results[[nm]]$setVisible(FALSE)
                return()
            }
            if (length(intersect(c(o$outcome, o$running, o$treatment), o$covs)) || identical(o$outcome, o$running)) jmvcore::reject("A variable can sit in one box only.")
            if (o$mode != "mde" && !is.finite(o$tau)) jmvcore::reject("Enter the effect to detect.")
            if (o$mode != "mde" && o$tau == 0) jmvcore::reject("The effect to detect must not be zero.")
            pp <- rd_guard(rd_prepare(self$data, o$outcome, o$running, o$treatment, o$covs, NULL, NULL, o$cutoff))
            dat <- cbind(pp$df$y, pp$df$x)
            fz <- if (!is.null(o$treatment)) pp$df$d else NULL
            base <- list(data = dat, cutoff = pp$c, alpha = o$alpha, covs = pp$covs, p = o$p, kernel = o$kernel, bwselect = o$bwselect, vce = o$vce, fuzzy = fz)
            private$.checkpoint()
            run <- function(f, extra) rd_guard(suppressWarnings(do.call(f, c(base[!vapply(base, is.null, TRUE)], extra))))
            res <- switch(o$mode,
                power = run(rdpower::rdpower, list(tau = o$tau)),
                mde = run(rdpower::rdmde, list(beta = o$beta)),
                sampsi = run(rdpower::rdsampsi, list(tau = o$tau, beta = o$beta)))
            r0 <- res
            db <- self$results$design
            db$addRow(rowKey = 1, values = list(item = "Observations", left = r0$N.l, right = r0$N.r))
            db$addRow(rowKey = 2, values = list(item = "Effective observations (inside the bandwidth)", left = r0$Nh.l, right = r0$Nh.r))
            db$addRow(rowKey = 3, values = list(item = "Bandwidth", left = r0$samph.l, right = r0$samph.r))
            rb <- self$results$res
            add <- function(i, item, rbc, conv = NaN) rb$addRow(rowKey = i, values = list(item = item, rbc = rbc, conv = conv))
            notes <- character(0)
            if (o$mode == "power") {
                add(1, sprintf("Power to detect an effect of %s", rd_fmt(o$tau, 3)), res$power.rbc, res$power.conv)
                add(2, "Standard error of the estimator", res$se.rbc, res$se.conv)
                cur <- self$results$curve
                mult <- c(0, 0.25, 0.5, 0.75, 1, 1.5, 2)
                for (i in seq_along(mult)) {
                    if (mult[i] == 1) pw <- res else pw <- run(rdpower::rdpower, list(tau = o$tau * max(mult[i], 1e-8)))
                    cur$addRow(rowKey = i, values = list(effect = o$tau * mult[i], rbc = pw$power.rbc, conv = pw$power.conv))
                }
                cur$setNote("a", "The first row (effect 0) is the probability of rejecting when there is no effect: it equals the significance level for the robust bias-corrected test and is a little larger for the conventional one, which ignores the smoothing bias.")
            } else if (o$mode == "mde") {
                add(1, sprintf("Smallest effect detected with power %s", rd_fmt(o$beta, 2)), res$mde, res$mde.conv)
                add(2, "Standard error of the estimator", res$se.rbc, res$se.conv)
            } else {
                add(1, sprintf("Effective sample size needed inside the bandwidth, total (power %s for %s)", rd_fmt(o$beta, 2), rd_fmt(o$tau, 3)), res$sampsi.h.tot)
                add(2, "... right of the cutoff", res$sampsi.h.r); add(3, "... left of the cutoff", res$sampsi.h.l)
                add(4, "Total sample size needed (inside and outside the bandwidth)", res$sampsi.tot)
                notes <- c(notes, "The sample sizes keep the shares and bandwidths of the current data: the new observations are assumed to be spread like the observed ones.")
            }
            notes <- c(notes, sprintf("%d observations used%s; bias-corrected (robust) inference as in the main RD analysis. The effect is that at the cutoff%s.", nrow(pp$df),
                                      if (pp$n_drop > 0) sprintf(" (%d with missing values dropped)", pp$n_drop) else "", if (!is.null(fz)) " (fuzzy design: the effect of the treatment received)" else ""))
            self$results$notes$setContent(paste0("<p>", paste(notes, collapse = " "), "</p>"))
        }
    )
)

