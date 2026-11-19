# Third-party software and data

rdfamily is distributed under the GNU General Public License, version 3 (see `LICENSE`).
It calls the following R packages, all released under GPL-3 (or compatible licences), and does not copy their code:

| Package | Used for | Authors / licence |
|---|---|---|
| rdrobust 4.1 | local polynomial RD, RD plots | Calonico, Cattaneo, Titiunik (and Farrell, Ma); GPL-3 |
| rddensity 3.0 | density (manipulation) test | Cattaneo, Jansson, Ma; GPL-3 |
| rdlocrand 3.0 | window selection, randomization inference | Cattaneo, Titiunik, Vazquez-Bare; GPL-3 |
| rdmulti 2.0 | multiple cutoffs | Cattaneo, Titiunik, Vazquez-Bare; GPL-3 |
| RDHonest 1.0 | honest confidence intervals | Kolesar; GPL-3 |
| rdhte 0.2 | heterogeneous treatment effects | Calonico, Cattaneo, Farrell, Palomba, Titiunik; GPL-3 |
| ggplot2, R6, jmvcore | plots, classes, jamovi interface | MIT; MIT; GPL (>= 2) |

## Example data (`data/`)

Real data are distributed with the CRAN packages named in `data/README.md` (`rdrobust`, `RDHonest`, `rdhte`),
all under GPL-3, and are reproduced here under that licence. The original sources are cited there
(Cattaneo, Frandsen and Titiunik, 2015; Lee, 2008; Ludwig and Miller, 2007; Battistin et al., 2009;
Lalive, 2008; Oreopoulos, 2006). The `sim_*.csv` files are simulated by `dev/make_data.R`.
