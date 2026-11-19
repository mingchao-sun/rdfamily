# jamovi analysis class: geographic and two-score RD through signed distance to the boundary.
# The RD is fitted with rdrobust on the signed distance (positive on the treated side, cutoff 0).

rdgeoClass <- R6::R6Class(
    "rdgeoClass",
    inherit = rdgeoBase,
    private = list(

        .run = function() {
            opts <- self$options
            rd_show_text(self$results, opts, "rdgeo")
            poly <- identical(opts$boundary, "polyline")
            need <- is.null(opts$outcome) || is.null(opts$x1) || is.null(opts$x2) ||
                (poly && (is.null(opts$treatment) || is.null(opts$bx) || is.null(opts$by)))
            if (need) {
                self$results$notes$setContent(if (poly)
                    "<p>Select an outcome, two coordinates, a treatment indicator and the two boundary vertex variables.</p>"
                    else "<p>Select an outcome and the two scores.</p>")
                return()
            }
            df <- data.frame(y = rd_num(self$data[[opts$outcome]]), x1 = rd_num(self$data[[opts$x1]]),
                             x2 = rd_num(self$data[[opts$x2]]))
            if (poly) df$d <- rd_num(self$data[[opts$treatment]])
            if (!is.null(opts$cluster)) df$cl <- as.character(self$data[[opts$cluster]])
            keep <- stats::complete.cases(df)
            n_drop <- sum(!keep); df <- df[keep, , drop = FALSE]

            if (poly) {
                if (!all(df$d %in% c(0, 1))) jmvcore::reject("The treatment indicator must be coded 0/1.")
                bx <- rd_num(self$data[[opts$bx]]); by <- rd_num(self$data[[opts$by]])
                ok <- !is.na(bx) & !is.na(by)
                bnd <- data.frame(x1 = bx[ok], x2 = by[ok])
                dist <- rd_guard(rd_dist_polyline(df$x1, df$x2, bnd$x1, bnd$x2))
                df$x <- ifelse(df$d == 1, dist, -dist)
            } else {
                df$x <- rd_signed_twoscore(df$x1, df$x2, opts$c1, opts$c2, opts$boundary)
                df$d <- as.numeric(df$x >= 0)
                bnd <- NULL
            }
            if (!any(df$x < 0) || !any(df$x >= 0))
                jmvcore::reject("Observations are needed on both sides of the boundary.")

            pp <- list(df = df, c = 0, covs = NULL)
            r <- rd_guard(rd_fit(pp, p = opts$p, kernel = opts$kernel, bwselect = opts$bwselect,
                                 vce = opts$vce, level = opts$level, donut = opts$donut))
            est <- rd_tidy(r)
            tb <- self$results$est
            tb$deleteRows()
            for (i in 1:3) tb$addRow(rowKey = i, values = as.list(est[i, ]))
            tb$setNote("n", "Effect at the boundary, averaged over boundary points, in units of the outcome. Distance is Euclidean; use projected (metric) coordinates, not raw latitude/longitude, for geographic boundaries.")

            dt <- self$results$design
            dt$deleteRows()
            two <- function(v, f = function(z) format(z)) c(f(v[1]), f(v[2]))
            rows <- list(list("Observations (control / treated side)", two(r$N)),
                         list("Effective observations", two(r$N_h)),
                         list("Bandwidth h (distance)", two(r$bws[1, ], rd_fmt)))
            for (i in seq_along(rows))
                dt$addRow(rowKey = i, values = list(item = rows[[i]][[1]], left = rows[[i]][[2]][1], right = rows[[i]][[2]][2]))
            self$results$notes$setContent(
                if (n_drop > 0) sprintf("<p>%d observation(s) with missing values were dropped.</p>", n_drop) else "")

            if (isTRUE(opts$plot))
                self$results$mapPlot$setState(list(pts = df[, c("x1", "x2", "d")], bnd = bnd,
                                                   rule = opts$boundary, c1 = opts$c1, c2 = opts$c2))
        },

        .plotGeo = function(image, ggtheme, theme, ...) {
            if (is.null(image$state)) return(FALSE)
            st <- image$state
            pts <- st$pts; pts$Treated <- factor(ifelse(pts$d == 1, "Treated", "Control"))
            g <- ggplot2::ggplot() +
                ggplot2::geom_point(data = pts, ggplot2::aes(x = x1, y = x2, colour = Treated), alpha = 0.6, size = 1.4) +
                ggplot2::labs(x = self$options$x1, y = self$options$x2, colour = NULL)
            if (!is.null(st$bnd)) {
                g <- g + ggplot2::geom_path(data = st$bnd, ggplot2::aes(x = x1, y = x2), linewidth = 0.9)
            } else {
                rx <- range(pts$x1); ry <- range(pts$x2); c1 <- st$c1; c2 <- st$c2
                if (identical(st$rule, "both")) seg <- data.frame(x = c(c1, c1), y = c(c2, c2), xend = c(c1, rx[2]), yend = c(ry[2], c2))
                else seg <- data.frame(x = c(c1, rx[1]), y = c(ry[1], c2), xend = c(c1, c1), yend = c(c2, c2))
                g <- g + ggplot2::geom_segment(data = seg, ggplot2::aes(x = x, y = y, xend = xend, yend = yend), linewidth = 0.9)
            }
            print(g + ggtheme)
            TRUE
        }
    )
)
