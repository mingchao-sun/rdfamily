# Method notes: Density Test

If units can precisely control the running variable, the density of the running variable jumps at the cutoff. The test (Cattaneo, Jansson and Ma, 2020) fits local polynomial density estimators on each side without pre-binning.

- H0: the density is continuous at the cutoff. A small p-value points to sorting or manipulation and weakens the RD design.
- Polynomial order / bias-correction order: order of the density fit (default 2) and of the bias correction (0 = p + 1).
- Model for the bias-correction: unrestricted (default) or restricted to a continuous density. Variance estimator: jackknife (default) or asymptotic plug-in.
- Manual bandwidth: 0 chooses it from the data. The sample table shows observations and bandwidths per side.
- A non-significant result does not prove that there is no manipulation; it only fails to find a jump.
