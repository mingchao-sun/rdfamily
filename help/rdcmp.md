# Method notes: Compare Methods

Shows how much the estimate depends on method and specification. The first row is the main specification (local linear, triangular kernel, MSE-optimal bandwidth); every other row changes one choice.

- Bandwidth selectors: MSE or coverage-error (CER) optimal, one or two bandwidths, and the median of selectors.
- Kernels: Epanechnikov and uniform instead of triangular. Local quadratic: p = 2.
- Honest CI: Armstrong and Kolesar interval based on a worst-case bias bound, with the rule-of-thumb smoothness constant.
- Local randomization: difference in means inside a window around the cutoff (default: the main bandwidth) with a permutation p-value; no standard error or interval. Skipped for fuzzy designs. A window as wide as the MSE bandwidth is usually too wide for as-if-random assignment; set a narrower half-window.
- rdrobust rows are bias-corrected with robust standard errors and intervals. Rows are not ranked. Choose the main specification before looking at results: reporting only the most favorable row is specification searching.
- Similar answers across rows support the finding; large differences signal sensitivity worth reporting. Use Robustness Checks to vary one setting at a time (cutoffs, bandwidth multiples, donut, order).
