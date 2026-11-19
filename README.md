# rdfamily: Regression Discontinuity Family for jamovi

A jamovi module for regression discontinuity (RD) designs, built on the CRAN packages
`rdrobust`, `rddensity` and `rdlocrand` (Cattaneo, Titiunik and co-authors). It follows the same
layout as `scmfamily`: one analysis per method in the menu group **RDD**.

| Analysis | What it does | Engine |
|---|---|---|
| Sharp / Fuzzy / Kink RD | Local polynomial RD with conventional, bias-corrected and robust inference; MSE/CER bandwidths; covariates, clustering, multiple cutoffs (normalised pooling), donut hole; first stage for fuzzy designs; RD plot. Kink design (RKD) via the derivative option | `rdrobust` |
| Density Test | Manipulation test for a density discontinuity at the cutoff, with density plot | `rddensity` |
| Covariate Balance | RD effect on each pre-determined covariate (or placebo outcome), forest plot in SD units | `rdrobust` |
| Power and Sample Size | Power, minimum detectable effect and sample size of an RD design, estimated from the data (pilot or earlier study); fuzzy designs and covariates | `rdpower` |
| Robustness Checks | Placebo cutoffs, bandwidth multipliers, donut radii, polynomial orders; tables and figures | `rdrobust` |
| Multiple Cutoffs | Cutoff-specific, weighted and pooled effects with a forest plot (Cattaneo et al., 2020) | `rdmulti` |
| Honest CIs | Armstrong-Kolesar honest confidence intervals with smoothness bound M, sharp or fuzzy | `RDHonest` |
| Geographic / Two-Score | RD on signed distance to a boundary: polyline from vertex variables, or two-score rule (both / either), with a map | `rdrobust` |
| Diff-in-Discontinuities | RD before vs after a second policy change; repeated cross-sections or panel differencing | `rdrobust` |
| Heterogeneous Effects (CATE) | RD effects by subgroup (nominal moderator, with Wald test of equal effects) or by a continuous moderator (linear interaction); forest plot | `rdhte` |
| Local Randomization | Window selection with covariates and randomization inference in a window (difference in means, KS, rank-sum) | `rdlocrand` |

## Data

One row per observation. Outcome and running variable numeric. Fuzzy RD: add a 0/1 treatment-received
variable. Multiple cutoffs: add a variable holding each unit's cutoff; the running variable is centered on it.
Example data: `data/rdsenate.csv` (US Senate elections; outcome `vote`, running variable `margin`, cutoff 0).
Expected result: conventional 7.41, robust CI [4.09, 10.92] (matches `rdrobust`).

## Design coverage and limits

Covered: sharp, fuzzy (binary or continuous treatment), kink and fuzzy kink, multiple cutoffs, geographic and two-score
boundaries, difference-in-discontinuities, honest CIs, local randomization, density test, covariate and placebo checks.
RD in time works with time as the running variable (use clustering or a narrow bandwidth for serial correlation).
Not included: extrapolation beyond the cutoff and flexible (machine-learning) CATE; heterogeneity is by one pre-specified moderator.

Boundary RD uses Euclidean distance: give projected (metric) coordinates. The estimate is an average over boundary points;
effects at individual boundary points are not reported.

## Install / build

```r
jmvtools::install(home = "C:/Program Files/jamovi 28.17.0.0")
```
Requires R packages `rdrobust`, `rddensity`, `rdlocrand` in the R used by jamovi (jamovi installs
Imports from CRAN when the module is built for distribution).

## Tests

`Rscript tests/smoke.R` runs every analysis headless on the example data; `Rscript tests/edge.R` runs about 70 edge cases (bad input, one-sided data, missing values) and shows the message each gives; `tests/plots.R` renders the figures. `help/*.md` is generated from the in-app Method notes by `dev/make_help.R`.

## Ribbon icon

`icon/analysis-rdd.svg` (74 x 44, same size and colours as the built-in jamovi icons and `scmfamily`): two fitted lines and a jump at a dashed cutoff.
jmvtools 28.17 cannot attach an icon to a module, so `dev/icon_preview.ps1` adds one CSS rule for the menu group RDD to jamovi's client
stylesheet (run in an Administrator PowerShell, then restart jamovi; `-Restore` removes the rule; a jamovi update overwrites it).

## Reference checks

`tests/reference.R` compares rd and rddens with `rdrobust` and `rddensity` called directly; `tests/reference2.R` repeats the idea for the
other analyses (rdcov, rdsens, rdcmp, rdhonest, rddid, rdgeo) with independent computations. The Stata comparisons are in `../stata_validation/`.
Run these in jamovi's own R with the bundled libraries as well: the package versions differ from the local ones.
