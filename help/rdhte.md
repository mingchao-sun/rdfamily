# Method notes: Heterogeneous Effects

Estimates how the RD effect varies with a moderator (Calonico, Cattaneo, Farrell, Palomba and Titiunik, 2025).

- Nominal moderator: one RD effect per group and a Wald test that all groups share the same effect.
- Continuous moderator: the effect at moderator = 0 and the linear change per unit; center the moderator to make the first row meaningful.
- Efficiency covariates: improve precision. One joint bandwidth: use a single bandwidth for all groups instead of one per group.
- Differences across groups are descriptive: groups differ in more than the moderator unless it is randomly assigned. With many groups use multiple-testing caution.
- Options as in the main RD analysis (variance estimator defaults to HC3).
