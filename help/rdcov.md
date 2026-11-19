# Method notes: Covariate Balance / Placebo Outcomes

Pre-determined covariates should not jump at the cutoff. Each covariate is used as the outcome of a separate RD, with its own optimal bandwidth.

- The table reports the bias-corrected estimate with robust standard error, p-value and interval, the bandwidths and the effective sample sizes.
- The plot rescales each effect by the covariate's standard deviation so that variables on different scales can be compared.
- With many covariates some p-values will be small by chance; look for a pattern, not a single rejection. The same analysis works for placebo outcomes (variables the treatment cannot affect).
- Options (order, bandwidth selector, kernel, variance, level, cluster) work as in the main RD analysis.
