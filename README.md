# rdfamily — regression discontinuity in jamovi

A jamovi module for regression discontinuity (RD) designs, built on the CRAN packages `rdrobust`, `rddensity`, `rdlocrand`, `rdmulti`, `rdhte`,
`rdpower` and `RDHonest`: sharp, fuzzy and kink designs with robust bias-corrected inference, manipulation tests, covariate and robustness checks,
multiple cutoffs, geographic boundaries, difference-in-discontinuities, honest intervals, local randomization and power. Chinese summary: [README.zh.md](README.zh.md).

## Analyses (jamovi menu: RDD)

| Analysis | What it does | Engine |
|---|---|---|
| **Sharp / Fuzzy / Kink RD** | Local polynomial RD with conventional, bias-corrected and robust inference; MSE/CER bandwidths; covariates, clustering, multiple cutoffs (normalised pooling), donut hole; first stage for fuzzy designs; RD plot. Kink design (RKD) via the derivative option | `rdrobust` |
| **Density Test** | Manipulation test for a density discontinuity at the cutoff, with density plot | `rddensity` |
| **Covariate Balance** | RD effect on each pre-determined covariate (or placebo outcome), forest plot in SD units | `rdrobust` |
| **Power and Sample Size** | Power, minimum detectable effect and sample size of an RD design, estimated from the data (pilot or earlier study); fuzzy designs and covariates | `rdpower` |
| **Robustness Checks** | Placebo cutoffs, bandwidth multipliers, donut radii, polynomial orders; tables and figures | `rdrobust` |
| **Multiple Cutoffs** | Cutoff-specific, weighted and pooled effects with a forest plot (Cattaneo et al., 2020) | `rdmulti` |
| **Honest CIs** | Armstrong-Kolesar honest confidence intervals with smoothness bound M, sharp or fuzzy | `RDHonest` |
| **Geographic / Two-Score** | RD on signed distance to a boundary: polyline from vertex variables, or two-score rule (both / either), with a map | `rdrobust` |
| **Diff-in-Discontinuities** | RD before vs after a second policy change; repeated cross-sections or panel differencing | `rdrobust` |
| **Heterogeneous Effects (CATE)** | RD effects by subgroup (nominal moderator, with Wald test of equal effects) or by a continuous moderator (linear interaction); forest plot | `rdhte` |
| **Local Randomization** | Window selection with covariates and randomization inference in a window (difference in means, KS, rank-sum) | `rdlocrand` |
| **Compare Methods** | One data set through several bandwidth selectors, kernels, polynomial orders, the honest interval and local randomization, listed side by side | several |

Every analysis has *Method notes* and *Data and setup guide* in its Output section.

## Install
- **jamovi library**: in jamovi open the modules button (top right), *jamovi library*, find *Regression Discontinuity Family* and install (once the module is listed).
- **Sideload**: download the `.jmo` file and use *Install from file* in the same menu. A `.jmo` works only on the operating system, processor type and jamovi version it was built for.
- **From source** (needs R and the jamovi compiler `jmvtools`; adjust the path to your jamovi folder):
```r
jmvtools::install(home = "C:/Program Files/jamovi 28.17.0.0")
```

## Use from R (Rj editor, scripts)
Every analysis is also an R function, for example
```r
rdfamily::rd(data = d, outcome = "vote", running = "margin", cutoff = 0)
```

## Data format
One row per observation. Outcome and running variable numeric. Fuzzy RD: add a 0/1 treatment-received variable. Multiple cutoffs: add a variable holding each
unit's cutoff; the running variable is centered on it. Rows with missing values are dropped and reported.

## Example data
Shown in jamovi under **Open > Data Library > Regression Discontinuity Family**; each entry says which analysis to use and which variable goes where.
Files in `data/` (sources in `data/README.md`):

| File | Design |
|---|---|
| `rdsenate.csv` | US Senate elections: outcome `vote`, running variable `margin`, cutoff 0. Expected: conventional 7.41, robust CI [4.09, 10.92] |
| `lee08_house.csv` | US House elections (Lee 2008) |
| `headstart.csv` | Head Start and child mortality (county poverty cutoff) |
| `retirement_food.csv` | Retirement and food spending (fuzzy) |
| `austria_unemployment.csv` | Unemployment duration by age around 50 (kink and difference designs) |
| `uk_school_leaving.csv` | Earnings by birth year around the 1947 school leaving age rise |
| `rdhte_elections.csv` | Election RD with candidate characteristics (heterogeneity) |
| `sim_multicutoff.csv`, `sim_boundary.csv`, `sim_kink.csv`, `sim_diffindisc.csv` | Simulated multiple cutoffs, geographic / two-score boundary, kink and difference-in-discontinuities |

## References
Papers and R packages behind each analysis appear in the References section of the jamovi output (defined in `jamovi/00refs.yaml`).

## Validation
`tests/reference.R` compares *Sharp / Fuzzy / Kink RD* and *Density Test* with `rdrobust` and `rddensity` called directly; `tests/reference2.R` repeats the idea for the other
analyses (covariates, robustness, comparison, honest intervals, difference-in-discontinuities, geographic) with independent computations; `tests/power.R` compares *Power and
Sample Size* with `rdpower`. The Stata comparisons (`rdrobust`, `rdpower`) are in `../stata_validation/`. `tests/smoke.R` runs every analysis headless and `tests/edge.R` about 70 edge cases
(bad input, one-sided data, missing values) showing the message each gives; `tests/plots.R` renders the figures. Run them in jamovi's own R with the bundled libraries as well: the package versions differ from the local ones.

## Known limitations
- Covered designs: sharp, fuzzy (binary or continuous treatment), kink and fuzzy kink, multiple cutoffs, geographic and two-score boundaries, difference-in-discontinuities, honest intervals, local randomization, density test, covariate and placebo checks.
- RD in time works with time as the running variable (use clustering or a narrow bandwidth for serial correlation).
- Not included: extrapolation beyond the cutoff and flexible (machine-learning) CATE; heterogeneity is by one pre-specified moderator.
- Boundary RD uses Euclidean distance: give projected (metric) coordinates. The estimate is an average over boundary points; effects at individual boundary points are not reported.

## Notes for developers
- Layout: `R/*.b.R` and `jamovi/*.yaml` are the jamovi front end around the RD packages; `dev/gen_power.py` generates the power analysis definition; `help/*.md` is generated from the in-app Method notes by `dev/make_help.R`.
- Tests: `Rscript tests/smoke.R`, `tests/edge.R`, `tests/plots.R`, `tests/reference.R`, `tests/reference2.R`, `tests/power.R` (reference packages in a library named by `RD_REFLIB`); `tests/ui_checklist.md` lists what to check by hand in jamovi.
- Ribbon icon: `icon/analysis-rdd.svg` (74 x 44): two fitted lines and a jump at a dashed cutoff. jmvtools 28.17 cannot attach an icon to a module, so `dev/icon_preview.ps1` adds one CSS rule for the menu group to jamovi's client stylesheet (administrator PowerShell, restart jamovi afterwards; `-Restore` removes the rule).

## How to cite
Sun, M. *rdfamily: Regression Discontinuity Family for jamovi* (jamovi module). https://github.com/mingchao-sun/rdfamily. Please also cite the papers and packages behind the analysis you use (listed in the output).

## License
GPL-3, as stated in `DESCRIPTION`; third-party code and data are listed in `NOTICE.md`. Bug reports and suggestions: https://github.com/mingchao-sun/rdfamily/issues
