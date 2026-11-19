# Method notes: Honest Confidence Intervals

Armstrong and Kolesar (2020) build intervals that remain valid under a bound on the curvature of the regression function, without undersmoothing or bias-correction. The interval is the estimate plus or minus a critical value times the standard error, where the critical value allows for the worst-case bias.

- Smoothness bound M: the largest absolute second derivative allowed. 0 uses a rule of thumb from a global polynomial fit; results can be sensitive to M, so report a range.
- Bandwidth criterion: minimize worst-case MSE (default), honest interval length (FLCI) or optimal conditional test length (OCT).
- Standard errors: nearest-neighbor or Eicker-Huber-White. Manual bandwidth: overrides the criterion.
- The table gives the estimate, standard error, maximum bias and the honest interval. Suited to discrete running variables with few support points.
