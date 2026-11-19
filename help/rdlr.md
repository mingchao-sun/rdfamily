# Method notes: Local Randomization

An alternative framework to the continuity approach (Cattaneo, Frandsen and Titiunik, 2015): inside a small window around the cutoff units are treated as if the treatment were randomly assigned. Inference is by permutation and needs no bandwidth or smoothness assumption, only that the window is small enough for as-if randomness.

- Window: manual half-widths on each side of the cutoff, or selected with covariates (rdwinselect): the largest window in which covariates remain balanced, with minimum p-value above 0.15.
- Candidate windows and the window selection table: the minimum covariate p-value and binomial test of the treated/control count in each window.
- Test statistic: difference in means, Kolmogorov-Smirnov or Wilcoxon rank-sum. Polynomial adjustment: order of a polynomial in the running variable removed before testing (0 = none).
- Randomizations / seed: number of permutations and the random seed. The reported p-value tests the sharp null of no effect for any unit; the asymptotic p-value is a large-sample approximation.
