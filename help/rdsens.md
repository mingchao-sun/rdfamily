# Method notes: Robustness Checks

Each check re-estimates the main specification once per scenario; the first row is always the main estimate and the dashed line in the figures marks it. All rows report bias-corrected estimates with robust standard errors and intervals.

- Placebo cutoffs: fake cutoffs in running-variable units. Each uses only observations on one side of the true cutoff (the control side for cutoffs below it, the treated side above), so the real effect does not contaminate it. Estimates should be near zero.
- Bandwidth sensitivity: multiples of the selected bandwidth (1 = main). Estimates should be stable.
- Donut hole: removes observations within each radius; bandwidths are re-selected. A change suggests sorting near the cutoff.
- Polynomial order: orders to try; high orders give noisy estimates and are not recommended.
- A scenario that cannot be estimated (too few observations) is shown as an empty row.
