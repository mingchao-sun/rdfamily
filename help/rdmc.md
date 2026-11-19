# Method notes: Multiple Cutoffs

When groups face different cutoffs of the same score, RD effects can be estimated for each cutoff and then combined (Cattaneo, Keele, Titiunik and Vazquez-Bare, 2020).

- Cutoff rows: separate RD at each cutoff with its own bandwidth.
- Weighted: average of the cutoff-specific effects with weights proportional to local sample size. Pooled: all scores centered at their cutoff and a single RD fitted.
- Large differences across cutoffs suggest heterogeneity; the pooled estimate then describes an average over the cutoffs.
- Options as in the main RD analysis; Treatment received adds a fuzzy design.
