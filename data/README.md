# Example data

Real data come from the CRAN packages named below (all GPL); simulated files are marked *sim* and built by `dev/make_data.R`.

| File | Content | Source | Use with |
|---|---|---|---|
| `rdsenate.csv` | US Senate elections 1914-2010: `vote`, `margin` and covariates | `rdrobust_RDsenate`, rdrobust (Cattaneo, Frandsen and Titiunik, 2015) | RD, density, balance, robustness, local randomization, honest CIs, CATE (moderator `dmidterm`) |
| `lee08_house.csv` | House elections: `voteshare`, `margin` | `lee08`, RDHonest (Lee, 2008) | RD, density, honest CIs |
| `headstart.csv` | US counties: mortality `mortHS`, centered poverty rate `povrate`, covariates | `headst`, RDHonest (Ludwig and Miller, 2007) | RD, covariate balance |
| `retirement_food.csv` | Retirement `retired` (0/1), `food`, `elig_year` | `rcp`, RDHonest (Battistin et al., 2009) | fuzzy RD |
| `austria_unemployment.csv` | `duration`, `age`, `period` (0/1), `female` | `rebp`, RDHonest (Lalive, 2008) | difference-in-discontinuities |
| `uk_school_leaving.csv` | `earnings`, `yearat14` (cutoff 1947) | `cghs`, RDHonest (Oreopoulos, 2006) | honest CIs, discrete running variable |
| `rdhte_elections.csv` | `y`, `x` and moderators `w_left`, `w_ideology`, ... | `rdhte_dataset`, rdhte | heterogeneous effects |
| `sim_multicutoff.csv` | *sim* `outcome`, `score`, `cutoff`, `state` | simulated | multiple cutoffs (true effect 3) |
| `sim_boundary.csv` | *sim* `outcome`, `score1`, `score2`, `treated`, `bx`, `by` | simulated | geographic / two-score (true effect 2) |
| `sim_kink.csv` | *sim* `outcome`, `running` | simulated | kink (true slope change 0.5) |
| `sim_diffindisc.csv` | *sim* `outcome`, `score`, `period`, `id` | simulated | difference-in-discontinuities (true difference 2) |
