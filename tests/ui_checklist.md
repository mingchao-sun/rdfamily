# rdfamily: checklist for the new analysis

## RD Power and Sample Size (menu RDD > Validity)
Dataset: Senate elections (rdsenate). Outcome `vote`; Running variable `margin`; Cutoff 0; Calculate "Power for an effect"; Effect to detect 5.
Expect: power 0.819 (robust bias-corrected) and 0.965 (conventional); standard error 1.74; design table 595 and 702 observations, 360 and 323 effective, bandwidth 17.754; the power table runs from 0.050 at effect 0 to 0.99992 at effect 10 and shows 0.819 at effect 5.
Then: "Minimum detectable effect" (target power 0.8) -> 4.88 (robust), 4.09 (conventional). "Sample size for a power" with effect 5, power 0.8 -> 657 effective observations inside the bandwidth (291 right, 366 left), 1235 in total. Change the order to 2, the kernel to Uniform, the bandwidth selector to CER-optimal: the numbers change. Add covariates (termshouse, population). Add `tr` (margin > 0) as treatment received for a fuzzy design. Method notes and guide on/off.
Messages: effect 0 -> "must not be zero"; the same variable as outcome and running variable -> "one box only"; a cutoff outside the data -> message.
Note: the lee08_house data (6558 observations with many distinct values) can take several minutes for this analysis.
