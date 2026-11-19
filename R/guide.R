# "Data and setup guide" and "Method notes" shown at the top of each analysis when the
# matching options in the Output section are ticked. Guides name the sample dataset, the exact
# field settings and the expected result; notes explain the method and every option.

rd_settings <- function(rows) {
    paste0("<table style='border-collapse:collapse;margin:4px 0 8px 0'>",
           "<tr><th style='text-align:left;padding:2px 14px 2px 0;border-bottom:1px solid #999'>Field</th>",
           "<th style='text-align:left;padding:2px 0;border-bottom:1px solid #999'>Set to</th></tr>",
           paste0("<tr><td style='padding:2px 14px 2px 0'>", names(rows), "</td><td style='padding:2px 0'>",
                  unlist(rows), "</td></tr>", collapse = ""), "</table>")
}

rd_layout <- function(cols, rows, extra = NULL) {
    th <- paste0("<th style='padding:2px 14px 2px 0;text-align:left;border-bottom:1px solid #999'>", cols, "</th>", collapse = "")
    tr <- paste0("<tr>", vapply(rows, function(r) paste0("<td style='padding:2px 14px 2px 0'>", r, "</td>", collapse = ""), ""), "</tr>", collapse = "")
    paste0("<h4>Data layout</h4><p>One row per observation. Illustrative example:</p>",
           "<table style='border-collapse:collapse;margin:4px 0 8px 0'><tr>", th, "</tr>", tr, "</table>",
           "<ul>", extra, "</ul>")
}

rd_guide_raw <- function(key) {
    h <- function(title, intro) paste0("<h3>", title, ": data and setup</h3><p>", intro, "</p>")
    s <- function(title, ...) paste0("<h4>", title, "</h4>", ..., collapse = "")
    types <- "<li><b>Variable types in jamovi</b>: outcome and running variable Continuous; "
    switch(key,

    rd = paste0(
        h("Sharp / Fuzzy / Kink RD", "Estimates the jump (or, for a kink, the change in slope) of the outcome at a cutoff of the running variable."),
        s("Sample data 1: sharp RD", rd_settings(list(
            "Dataset" = "<i>rdsenate.csv</i>", "Outcome" = "vote", "Running variable" = "margin", "Cutoff" = "0")),
          "<p>Expected: conventional 7.414, robust CI [4.09, 10.92].</p>"),
        s("Sample data 2: fuzzy RD", rd_settings(list(
            "Dataset" = "<i>retirement_food.csv</i>", "Outcome" = "food",
            "Running variable" = "elig_year (years from pension eligibility)", "Treatment received" = "retired (0/1)", "Cutoff" = "0")),
          "<p>Expected: conventional about -127 (food spending falls on retirement), robust p about 0.04. The first-stage table shows the jump in retirement.</p>"),
        s("Sample data 3: kink and multiple cutoffs", rd_settings(list(
            "Kink" = "<i>sim_kink.csv</i>: Outcome = outcome, Running variable = running, tick Regression kink design (true slope change 0.5)",
            "Multiple cutoffs" = "<i>sim_multicutoff.csv</i>: Outcome = outcome, Running variable = score, Cutoff variable = cutoff (true effect 3). Use <i>Multiple Cutoffs</i> for cutoff-specific effects")),
          ""),
        rd_layout(c("outcome", "margin", "treated", "state"), list(c("42.1", "-3.2", "0", "A"), c("55.7", "1.4", "1", "A"), c("47.0", "0.6", "1", "B")),
            paste0("<li>The running variable must be numeric with observations on both sides of the cutoff. Treatment is assigned when it is at or above the cutoff.</li>",
                   types, "treatment received 0/1 (fuzzy design only); cluster variable Nominal or ID.</li>",
                   "<li>Rows with a missing value in any selected variable are dropped; the count is reported in the Notes.</li>"))),

    rddens = paste0(
        h("Density Test", "Tests whether the density of the running variable is continuous at the cutoff; a jump suggests sorting or manipulation."),
        s("Sample data", rd_settings(list("Dataset" = "<i>rdsenate.csv</i>", "Running variable" = "margin", "Cutoff" = "0")),
          "<p>Expected: T = -0.875, p = 0.381 (no evidence of manipulation). <i>lee08_house.csv</i> (running variable margin) gives p = 0.15.</p>"),
        rd_layout(c("margin"), list(c("-3.2"), c("1.4"), c("0.6")),
            "<li>Only the running variable is needed. With several cutoffs, add a cutoff variable and the scores are centered on it.</li>")),

    rdcov = paste0(
        h("Covariate Balance / Placebo Outcomes", "Runs the RD on variables that the treatment cannot affect. A jump in a pre-determined covariate casts doubt on the design."),
        s("Sample data", rd_settings(list("Dataset" = "<i>rdsenate.csv</i>",
            "Covariates" = "termshouse, population, presdemvoteshlag1", "Running variable" = "margin", "Cutoff" = "0")),
          "<p>Expected: three small, non-significant effects (robust p about 0.56, 0.63, 0.47). <i>headstart.csv</i> (running variable povrate, covariates hs60, urban, black) is a second example.</p>"),
        rd_layout(c("age", "income", "margin"), list(c("34", "28.1", "-3.2"), c("41", "31.5", "1.4"), c("29", "25.0", "0.6")),
            "<li>Use only variables fixed before treatment, or outcomes the treatment should not move (placebo outcomes).</li>")),

    rdpower = paste0(
        h("RD Power and Sample Size", "Answers: how likely is an RD study to detect an effect of a given size, what is the smallest effect it can detect, and how many observations does it need? It uses the data to estimate the variance, the bias and the bandwidth around the cutoff, so the data can be a pilot or an earlier study."),
        s("Sample data", rd_settings(list(
            "Dataset" = "<i>rdsenate.csv</i>", "Outcome" = "vote", "Running variable" = "margin", "Cutoff" = "0", "Calculate" = "Power for an effect", "Effect to detect" = "5")),
          "<p>Expected: power 0.819 for the robust bias-corrected test (standard error 1.74) and 0.965 for the conventional one; the effective sample is 360 observations left and 323 right of the cutoff within bandwidth 17.75. ",
          "Switch to <i>Minimum detectable effect</i> (target power 0.8): 4.88. Switch to <i>Sample size for a power</i> with effect 5 and power 0.8: 657 effective observations inside the bandwidth (291 right, 366 left), 1235 in total. Large samples with many distinct values can take a minute.</p>")),

    rdsens = paste0(
        h("Robustness Checks", "Re-estimates the RD effect under alternative placebo cutoffs, bandwidths, donut holes and polynomial orders."),
        s("Sample data", rd_settings(list("Dataset" = "<i>rdsenate.csv</i>", "Outcome" = "vote", "Running variable" = "margin",
            "Placebo cutoffs" = "-10,-5,5,10", "Bandwidth multipliers" = "0.5,0.75,1,1.25,1.5,2", "Donut radii" = "0,0.5,1", "Polynomial orders" = "1,2,3")),
          "<p>Tick the table and figure boxes of the checks you want. Expected: main estimate 7.507; at 1 &times; h the bandwidth row equals the main row.</p>"),
        rd_layout(c("outcome", "margin"), list(c("42.1", "-3.2"), c("55.7", "1.4")),
            "<li>The settings in Estimation are the main specification; every check changes one thing at a time.</li>")),

    rdlr = paste0(
        h("Local Randomization", "Treats observations inside a narrow window around the cutoff as if randomly assigned and tests the sharp null by permutation."),
        s("Sample data", rd_settings(list("Dataset" = "<i>rdsenate.csv</i>", "Outcome" = "vote", "Running variable" = "margin",
            "Window" = "Manual, width left 2, width right 2", "Randomizations" = "1000")),
          "<p>Expected: difference in means about 10.2, p &lt; .001. To choose the window from data, set Window to <i>Selected with covariates</i> and add covariates such as termshouse and population.</p>"),
        rd_layout(c("outcome", "margin", "covariate"), list(c("42.1", "-3.2", "5"), c("55.7", "1.4", "7")),
            "<li>Needs enough observations on both sides inside the window (at least three). Covariates are used only for window selection.</li>")),

    rdmc = paste0(
        h("Multiple Cutoffs", "Different groups face different cutoffs of the same score. Gives one effect per cutoff, a weighted average and a pooled estimate."),
        s("Sample data", rd_settings(list("Dataset" = "<i>sim_multicutoff.csv</i>",
            "Outcome" = "outcome", "Running variable" = "score (raw score, not centered)", "Cutoff variable" = "cutoff")),
          "<p>Expected: pooled effect about 3.1; each cutoff-specific effect close to the true value 3.</p>"),
        rd_layout(c("outcome", "score", "cutoff"), list(c("12.4", "38.0", "40"), c("14.9", "52.5", "50"), c("17.1", "63.0", "60")),
            "<li>Use the raw score and a variable holding the cutoff each row faces. At most 30 distinct cutoffs.</li>")),

    rdhonest = paste0(
        h("Honest Confidence Intervals", "Confidence intervals that account for the worst-case smoothing bias given a bound M on the curvature of the regression function."),
        s("Sample data", rd_settings(list("Dataset" = "<i>rdsenate.csv</i>", "Outcome" = "vote", "Running variable" = "margin", "Smoothness bound M" = "0 (rule of thumb)")),
          "<p>Expected: estimate 8.03, honest CI [3.82, 12.24]. <i>uk_school_leaving.csv</i> (earnings on yearat14, cutoff 1947) has a discrete running variable, where honest intervals are especially useful.</p>"),
        rd_layout(c("outcome", "margin"), list(c("42.1", "-3.2"), c("55.7", "1.4")),
            "<li>Handles discrete running variables. Leave M at 0 for the data-driven rule of thumb, or enter a substantive bound.</li>")),

    rdgeo = paste0(
        h("Geographic / Two-Score Boundary", "Estimates the effect at a boundary in two dimensions through the signed distance to that boundary."),
        s("Sample data", rd_settings(list("Dataset" = "<i>sim_boundary.csv</i>", "Outcome" = "outcome", "Coordinate / score 1" = "score1",
            "Coordinate / score 2" = "score2", "Boundary" = "Two scores: treated if both reach their cutoffs", "Cutoffs" = "0 and 0")),
          "<p>Expected: about 1.98 (true effect 2). For the polyline version choose Polyline, add Treatment = treated, Boundary vertex 1 = bx and vertex 2 = by.</p>"),
        rd_layout(c("outcome", "x", "y", "treated", "bx", "by"), list(c("3.1", "120.5", "40.2", "1", "100", "0"), c("1.2", "98.0", "35.0", "0", "100", "80"), c("", "", "", "", "140", "80")),
            paste0("<li>For a polyline boundary list its vertices in order in two columns; leave the other rows empty.</li>",
                   "<li>Use projected (metric) coordinates, not raw latitude and longitude. Distance is Euclidean.</li>"))),

    rddid = paste0(
        h("Difference-in-Discontinuities", "Compares the jump at the cutoff before and after a policy change, removing a discontinuity that was there already."),
        s("Sample data 1: repeated cross-section", rd_settings(list("Dataset" = "<i>austria_unemployment.csv</i>",
            "Outcome" = "duration", "Running variable" = "age", "Period" = "period (0 = before, 1 = after)", "Cutoff" = "50")),
          "<p>The jump at age 50 is small before the reform and large after it.</p>"),
        s("Sample data 2: panel", rd_settings(list("Dataset" = "<i>sim_diffindisc.csv</i>", "Outcome" = "outcome", "Running variable" = "score",
            "Period" = "period", "Unit" = "id", "Cutoff" = "0")),
          "<p>Expected: difference about 1.97 (true 2). Without the unit, rows are treated as independent cross-sections.</p>"),
        rd_layout(c("outcome", "age", "period", "id"), list(c("12.1", "49.5", "0", "1"), c("14.0", "49.5", "1", "1"), c("9.8", "51.0", "0", "2")),
            "<li>The period variable must have exactly two values; the larger or later one is the post period. In panel mode the running variable must be the same in both periods for each unit.</li>")),

    rdhte = paste0(
        h("Heterogeneous Effects", "Estimates how the RD effect differs across subgroups or along a continuous moderator."),
        s("Sample data", rd_settings(list("Dataset" = "<i>rdsenate.csv</i>", "Outcome" = "vote", "Running variable" = "margin",
            "Moderator" = "dmidterm (set to Nominal in jamovi)")),
          "<p>Expected: 7.63 (not a midterm year) and 7.13 (midterm), test of equal effects p = 0.90. <i>rdhte_elections.csv</i> (Outcome y, Running variable x, Moderator w_left or w_ideology set to Nominal) is a larger example.</p>"),
        rd_layout(c("outcome", "margin", "group"), list(c("42.1", "-3.2", "0"), c("55.7", "1.4", "1"), c("47.0", "0.6", "1")),
            "<li>A Nominal or Ordinal moderator gives one effect per group (at most 12); a Continuous one gives the effect at 0 and the linear change per unit. Set the type in the data tab.</li>")),

    rdcmp = paste0(
        h("Compare Methods", "Runs one RD data set through several methods and specifications and lists the estimates side by side."),
        s("Sample data", rd_settings(list("Dataset" = "<i>rdsenate.csv</i>", "Outcome" = "vote", "Running variable" = "margin", "Cutoff" = "0")),
          "<p>Expected: main row 7.507 (robust CI [4.09, 10.92]); honest CI estimate 8.03 [3.82, 12.24]; all rows positive and clearly above zero. For a fuzzy design use <i>retirement_food.csv</i> (Outcome food, Running variable elig_year, Treatment received retired); local randomization is then skipped.</p>"),
        rd_layout(c("outcome", "margin", "treated"), list(c("42.1", "-3.2", "0"), c("55.7", "1.4", "1")),
            "<li>Same data requirements as the main RD analysis. Missing values are dropped.</li>")),

    "")
}

# Library names of the example data (as listed in File > Open > Data Library).
rd_data_names <- c(
    "rdsenate.csv" = "US Senate elections",
    "lee08_house.csv" = "US House elections (Lee 2008)",
    "headstart.csv" = "Head Start and child mortality",
    "retirement_food.csv" = "Retirement and food spending (fuzzy)",
    "austria_unemployment.csv" = "Unemployment duration in Austria",
    "uk_school_leaving.csv" = "UK school leaving age",
    "rdhte_elections.csv" = "Election data for heterogeneity",
    "sim_multicutoff.csv" = "Simulated multiple cutoffs",
    "sim_boundary.csv" = "Simulated boundary",
    "sim_kink.csv" = "Simulated kink",
    "sim_diffindisc.csv" = "Simulated difference-in-discontinuities")

# Shows each example data set by its Data Library name (bold) and says where to open it.
rd_guide_html <- function(key) {
    x <- rd_guide_raw(key)
    for (f in names(rd_data_names))
        x <- gsub(paste0("<i>", f, "</i>"), paste0("<b>", rd_data_names[[f]], "</b>"), x, fixed = TRUE)
    sub("</p>", paste0("</p><p><i>Open the sample data from File &gt; Open &gt; Data Library &gt; ",
                       "Regression Discontinuity Family; the library lists each data set by the bold name below.</i></p>"),
        x, fixed = TRUE)
}

rd_notes_html <- function(key) {
    est <- paste0("<li><strong>Conventional</strong>: local polynomial estimate with conventional standard error. ",
                  "<strong>Bias-corrected</strong>: removes the leading smoothing bias. <strong>Robust</strong>: bias-corrected estimate with a standard error that accounts for the correction; report this one (Calonico, Cattaneo and Titiunik, 2014).</li>")
    opt <- paste0("<li><strong>Polynomial order p</strong>: order of the local fit (1 = local linear, the default). <strong>Bias-correction order q</strong>: order used to estimate the bias (0 = p + 1).</li>",
                  "<li><strong>Kernel</strong>: weights observations by distance from the cutoff; triangular is the default and boundary-optimal.</li>",
                  "<li><strong>Bandwidth selector</strong>: MSE-optimal minimizes mean squared error (best for the point estimate); CER-optimal minimizes coverage error (better for intervals). <i>rd</i> = one common bandwidth, <i>two</i> = one per side, <i>sum</i>/<i>comb</i> = combinations.</li>",
                  "<li><strong>Variance estimator</strong>: nearest-neighbor (default) or heteroskedasticity-robust HC0-HC3. <strong>Confidence level</strong>: for all intervals.</li>")
    h <- function(t, ...) paste0("<h2>", t, "</h2>", ...)
    switch(key,

    rd = h("Method notes: Regression Discontinuity",
        "<p>Units are assigned to treatment when the running variable reaches a cutoff. Comparing units just below and just above identifies the effect at the cutoff if potential outcomes are continuous there and units cannot precisely sort around it.</p>",
        "<h3>Designs</h3><ul>",
        "<li><strong>Sharp</strong>: everyone above the cutoff is treated. <strong>Fuzzy</strong>: add <em>Treatment received</em>; the estimate is the jump in the outcome divided by the jump in treatment (a local average effect for compliers) and the first-stage jump is shown.</li>",
        "<li><strong>Kink</strong>: estimates the change in the slope of the outcome at the cutoff (Card et al., 2015); p is raised to 2 if needed.</li>",
        "<li><strong>Cutoff variable</strong>: for several cutoffs, the running variable is centered on each row's cutoff and pooled.</li></ul>",
        "<h3>Options</h3><ul>",
        "<li><strong>Covariates</strong>: added to the local regression to gain precision; they do not change what is estimated. <strong>Cluster</strong>: cluster-robust variance.</li>",
        "<li><strong>Donut hole radius</strong>: drops observations closer than this to the cutoff, useful when precise sorting is suspected.</li>",
        "<li><strong>Manual bandwidth h and b</strong>: overrides the selector; b is the bandwidth for the bias estimate (default = h).</li>", opt, "</ul>",
        "<h3>Reading the results</h3><ul>", est,
        "<li>The design table gives total and effective (inside the bandwidth) observations. The RD plot shows binned means and a global polynomial fit; it is descriptive, the estimate comes from the local fit.</li>",
        "<li>Always accompany a result with a density test, covariate balance and robustness checks.</li></ul>"),

    rddens = h("Method notes: Density Test",
        "<p>If units can precisely control the running variable, the density of the running variable jumps at the cutoff. The test (Cattaneo, Jansson and Ma, 2020) fits local polynomial density estimators on each side without pre-binning.</p><ul>",
        "<li><strong>H0</strong>: the density is continuous at the cutoff. A small p-value points to sorting or manipulation and weakens the RD design.</li>",
        "<li><strong>Polynomial order / bias-correction order</strong>: order of the density fit (default 2) and of the bias correction (0 = p + 1).</li>",
        "<li><strong>Model for the bias-correction</strong>: unrestricted (default) or restricted to a continuous density. <strong>Variance estimator</strong>: jackknife (default) or asymptotic plug-in.</li>",
        "<li><strong>Manual bandwidth</strong>: 0 chooses it from the data. The sample table shows observations and bandwidths per side.</li>",
        "<li>A non-significant result does not prove that there is no manipulation; it only fails to find a jump.</li></ul>"),

    rdcov = h("Method notes: Covariate Balance / Placebo Outcomes",
        "<p>Pre-determined covariates should not jump at the cutoff. Each covariate is used as the outcome of a separate RD, with its own optimal bandwidth.</p><ul>",
        "<li>The table reports the bias-corrected estimate with robust standard error, p-value and interval, the bandwidths and the effective sample sizes.</li>",
        "<li>The plot rescales each effect by the covariate's standard deviation so that variables on different scales can be compared.</li>",
        "<li>With many covariates some p-values will be small by chance; look for a pattern, not a single rejection. The same analysis works for placebo outcomes (variables the treatment cannot affect).</li>",
        "<li>Options (order, bandwidth selector, kernel, variance, level, cluster) work as in the main RD analysis.</li></ul>"),

    rdpower = h("Method notes: Power and Sample Size",
        "<p>Power is the probability of rejecting the null of no effect at the cutoff when the true effect is the stated one. The calculation (Cattaneo, Titiunik and Vazquez-Bare, 2019) takes the local polynomial estimator of the main RD analysis, estimates its bias and variance from the data inside the bandwidth, and treats the estimator as normal around the true effect.</p><ul>",
        "<li><strong>Power for an effect</strong>: the power of the test for the effect you enter, for the robust bias-corrected test and the conventional one; the table also gives the power against other effects.</li>",
        "<li><strong>Minimum detectable effect</strong>: the smallest effect that the test detects with the target power.</li>",
        "<li><strong>Sample size for a power</strong>: the number of observations needed inside the bandwidth, and in total, for the effect and the target power, assuming new observations are spread over the running variable like the observed ones.</li>",
        "<li>Options (order, kernel, bandwidth selector, variance, covariates, fuzzy treatment) work as in the main RD analysis. The effect is in outcome units; for a fuzzy design it is the effect of the treatment received.</li></ul>",
        "<p>The variance and bandwidth are estimated, so the answers are for a design like the one in the data. For a new study use pilot data or an earlier study with a similar outcome. Results equal the R package rdpower and the Stata command of the same name.</p>"),

    rdsens = h("Method notes: Robustness Checks",
        "<p>Each check re-estimates the main specification once per scenario; the first row is always the main estimate and the dashed line in the figures marks it. All rows report bias-corrected estimates with robust standard errors and intervals.</p><ul>",
        "<li><strong>Placebo cutoffs</strong>: fake cutoffs in running-variable units. Each uses only observations on one side of the true cutoff (the control side for cutoffs below it, the treated side above), so the real effect does not contaminate it. Estimates should be near zero.</li>",
        "<li><strong>Bandwidth sensitivity</strong>: multiples of the selected bandwidth (1 = main). Estimates should be stable.</li>",
        "<li><strong>Donut hole</strong>: removes observations within each radius; bandwidths are re-selected. A change suggests sorting near the cutoff.</li>",
        "<li><strong>Polynomial order</strong>: orders to try; high orders give noisy estimates and are not recommended.</li>",
        "<li>A scenario that cannot be estimated (too few observations) is shown as an empty row.</li></ul>"),

    rdlr = h("Method notes: Local Randomization",
        "<p>An alternative framework to the continuity approach (Cattaneo, Frandsen and Titiunik, 2015): inside a small window around the cutoff units are treated as if the treatment were randomly assigned. Inference is by permutation and needs no bandwidth or smoothness assumption, only that the window is small enough for as-if randomness.</p><ul>",
        "<li><strong>Window</strong>: manual half-widths on each side of the cutoff, or selected with covariates (rdwinselect): the largest window in which covariates remain balanced, with minimum p-value above 0.15.</li>",
        "<li><strong>Candidate windows</strong> and the <strong>window selection table</strong>: the minimum covariate p-value and binomial test of the treated/control count in each window.</li>",
        "<li><strong>Test statistic</strong>: difference in means, Kolmogorov-Smirnov or Wilcoxon rank-sum. <strong>Polynomial adjustment</strong>: order of a polynomial in the running variable removed before testing (0 = none).</li>",
        "<li><strong>Randomizations / seed</strong>: number of permutations and the random seed. The reported p-value tests the sharp null of no effect for any unit; the asymptotic p-value is a large-sample approximation.</li></ul>"),

    rdmc = h("Method notes: Multiple Cutoffs",
        "<p>When groups face different cutoffs of the same score, RD effects can be estimated for each cutoff and then combined (Cattaneo, Keele, Titiunik and Vazquez-Bare, 2020).</p><ul>",
        "<li><strong>Cutoff rows</strong>: separate RD at each cutoff with its own bandwidth.</li>",
        "<li><strong>Weighted</strong>: average of the cutoff-specific effects with weights proportional to local sample size. <strong>Pooled</strong>: all scores centered at their cutoff and a single RD fitted.</li>",
        "<li>Large differences across cutoffs suggest heterogeneity; the pooled estimate then describes an average over the cutoffs.</li>",
        "<li>Options as in the main RD analysis; <strong>Treatment received</strong> adds a fuzzy design.</li></ul>"),

    rdhonest = h("Method notes: Honest Confidence Intervals",
        "<p>Armstrong and Kolesar (2020) build intervals that remain valid under a bound on the curvature of the regression function, without undersmoothing or bias-correction. The interval is the estimate plus or minus a critical value times the standard error, where the critical value allows for the worst-case bias.</p><ul>",
        "<li><strong>Smoothness bound M</strong>: the largest absolute second derivative allowed. 0 uses a rule of thumb from a global polynomial fit; results can be sensitive to M, so report a range.</li>",
        "<li><strong>Bandwidth criterion</strong>: minimize worst-case MSE (default), honest interval length (FLCI) or optimal conditional test length (OCT).</li>",
        "<li><strong>Standard errors</strong>: nearest-neighbor or Eicker-Huber-White. <strong>Manual bandwidth</strong>: overrides the criterion.</li>",
        "<li>The table gives the estimate, standard error, maximum bias and the honest interval. Suited to discrete running variables with few support points.</li></ul>"),

    rdgeo = h("Method notes: Geographic / Two-Score Boundary",
        "<p>With two running variables (coordinates, or two scores), treatment switches on across a boundary. The analysis reduces the problem to one dimension: the signed distance from each observation to the boundary (positive on the treated side), then an ordinary RD at zero.</p><ul>",
        "<li><strong>Polyline</strong>: boundary given by ordered vertices in two columns; needs a treatment indicator for the sign.</li>",
        "<li><strong>Two scores</strong>: treated if <em>both</em> scores reach their cutoffs, or if <em>either</em> does; the boundary is the corresponding corner.</li>",
        "<li>The estimate averages the effect over boundary points. Effects can differ along the boundary; map the sample and check balance.</li>",
        "<li>Use metric coordinates: distance is Euclidean. Keep spatial dependence in mind and use a cluster variable if needed. Estimation options as in the main RD analysis.</li></ul>"),

    rddid = h("Method notes: Difference-in-Discontinuities",
        "<p>If an earlier discontinuity or other policy already exists at the same cutoff, compare the jump before and after the change (Grembi, Nannicini and Troiano, 2016).</p><ul>",
        "<li><strong>Repeated cross-sections</strong> (no unit): the RD is estimated in each period with the same bandwidth (average of the two optimal ones); the difference has a standard error from the two independent estimates.</li>",
        "<li><strong>Panel</strong> (unit given): the outcome is first differenced within unit and the RD is fitted on the change, which removes unit fixed effects.</li>",
        "<li>Identifying assumption: without the policy change the discontinuity would have been the same in both periods.</li>",
        "<li>Period must have two values; the later one is post. Estimates are bias-corrected with robust standard errors.</li></ul>"),

    rdhte = h("Method notes: Heterogeneous Effects",
        "<p>Estimates how the RD effect varies with a moderator (Calonico, Cattaneo, Farrell, Palomba and Titiunik, 2025).</p><ul>",
        "<li><strong>Nominal moderator</strong>: one RD effect per group and a Wald test that all groups share the same effect.</li>",
        "<li><strong>Continuous moderator</strong>: the effect at moderator = 0 and the linear change per unit; center the moderator to make the first row meaningful.</li>",
        "<li><strong>Efficiency covariates</strong>: improve precision. <strong>One joint bandwidth</strong>: use a single bandwidth for all groups instead of one per group.</li>",
        "<li>Differences across groups are descriptive: groups differ in more than the moderator unless it is randomly assigned. With many groups use multiple-testing caution.</li>",
        "<li>Options as in the main RD analysis (variance estimator defaults to HC3).</li></ul>"),

    rdcmp = h("Method notes: Compare Methods",
        "<p>Shows how much the estimate depends on method and specification. The first row is the main specification (local linear, triangular kernel, MSE-optimal bandwidth); every other row changes one choice.</p><ul>",
        "<li><strong>Bandwidth selectors</strong>: MSE or coverage-error (CER) optimal, one or two bandwidths, and the median of selectors.</li>",
        "<li><strong>Kernels</strong>: Epanechnikov and uniform instead of triangular. <strong>Local quadratic</strong>: p = 2.</li>",
        "<li><strong>Honest CI</strong>: Armstrong and Kolesar interval based on a worst-case bias bound, with the rule-of-thumb smoothness constant.</li>",
        "<li><strong>Local randomization</strong>: difference in means inside a window around the cutoff (default: the main bandwidth) with a permutation p-value; no standard error or interval. Skipped for fuzzy designs. A window as wide as the MSE bandwidth is usually too wide for as-if-random assignment; set a narrower half-window.</li>",
        "<li>rdrobust rows are bias-corrected with robust standard errors and intervals. Rows are not ranked. Choose the main specification before looking at results: reporting only the most favorable row is specification searching.</li>",
        "<li>Similar answers across rows support the finding; large differences signal sensitivity worth reporting. Use Robustness Checks to vary one setting at a time (cutoffs, bandwidth multiples, donut, order).</li></ul>"),

    "")
}

# Called at the start of every analysis run.
rd_show_text <- function(results, opts, key) {
    if (isTRUE(opts$showGuide)) results$guide$setContent(rd_guide_html(key))
    if (isTRUE(opts$showHelp)) results$helpText$setContent(rd_notes_html(key))
}
