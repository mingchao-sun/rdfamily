# Method notes: Difference-in-Discontinuities

If an earlier discontinuity or other policy already exists at the same cutoff, compare the jump before and after the change (Grembi, Nannicini and Troiano, 2016).

- Repeated cross-sections (no unit): the RD is estimated in each period with the same bandwidth (average of the two optimal ones); the difference has a standard error from the two independent estimates.
- Panel (unit given): the outcome is first differenced within unit and the RD is fitted on the change, which removes unit fixed effects.
- Identifying assumption: without the policy change the discontinuity would have been the same in both periods.
- Period must have two values; the later one is post. Estimates are bias-corrected with robust standard errors.
