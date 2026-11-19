# rdfamily 1.0.0

* First public release (jamovi library submission). Contains everything listed below; the earlier 0.x entries are development history.

# rdfamily 1.1.0

* New analysis **RD Power and Sample Size** (menu RDD > Validity): power for an effect, minimum detectable effect and sample size of an RD design, built on the R package `rdpower` (Cattaneo, Titiunik and Vazquez-Bare, 2019). Results equal the package on the same data.

# rdfamily 1.0.0

First release. Eleven analyses in the menu group RDD:

* Estimation: Sharp / Fuzzy / Kink RD, Multiple Cutoffs, Geographic / Two-Score Boundary, Difference-in-Discontinuities, Heterogeneous Effects (CATE).
* Validity: Density Test, Covariate Balance, Robustness Checks.
* Alternative inference: Honest CIs, Local Randomization.
* Compare: Compare Methods (side-by-side estimates from different methods and specifications).

Every analysis has *Method notes* and *Data and setup guide* in its Output section. Eleven example data sets are in the Data Library.

* Fixed: *Heterogeneous Effects* passed the kernel name to the rdhte package in a form it does not recognise, so every run silently used the uniform kernel. The chosen kernel is now used (cross-checked against Stata `rdhte`).
* Fixed: *Heterogeneous Effects* failed with "'names' attribute ... must be the same length" under the rdhte 0.1.0 package bundled with jamovi.
