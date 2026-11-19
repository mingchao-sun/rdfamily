# Method notes: Regression Discontinuity

Units are assigned to treatment when the running variable reaches a cutoff. Comparing units just below and just above identifies the effect at the cutoff if potential outcomes are continuous there and units cannot precisely sort around it.

## Designs

- Sharp: everyone above the cutoff is treated. Fuzzy: add Treatment received; the estimate is the jump in the outcome divided by the jump in treatment (a local average effect for compliers) and the first-stage jump is shown.
- Kink: estimates the change in the slope of the outcome at the cutoff (Card et al., 2015); p is raised to 2 if needed.
- Cutoff variable: for several cutoffs, the running variable is centered on each row's cutoff and pooled.

## Options

- Covariates: added to the local regression to gain precision; they do not change what is estimated. Cluster: cluster-robust variance.
- Donut hole radius: drops observations closer than this to the cutoff, useful when precise sorting is suspected.
- Manual bandwidth h and b: overrides the selector; b is the bandwidth for the bias estimate (default = h).
- Polynomial order p: order of the local fit (1 = local linear, the default). Bias-correction order q: order used to estimate the bias (0 = p + 1).
- Kernel: weights observations by distance from the cutoff; triangular is the default and boundary-optimal.
- Bandwidth selector: MSE-optimal minimizes mean squared error (best for the point estimate); CER-optimal minimizes coverage error (better for intervals). rd = one common bandwidth, two = one per side, sum/comb = combinations.
- Variance estimator: nearest-neighbor (default) or heteroskedasticity-robust HC0-HC3. Confidence level: for all intervals.

## Reading the results

- Conventional: local polynomial estimate with conventional standard error. Bias-corrected: removes the leading smoothing bias. Robust: bias-corrected estimate with a standard error that accounts for the correction; report this one (Calonico, Cattaneo and Titiunik, 2014).
- The design table gives total and effective (inside the bandwidth) observations. The RD plot shows binned means and a global polynomial fit; it is descriptive, the estimate comes from the local fit.
- Always accompany a result with a density test, covariate balance and robustness checks.
