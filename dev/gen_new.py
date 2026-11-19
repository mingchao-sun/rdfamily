# Generates the .a/.r/.u.yaml files of rdmc, rdhonest, rdgeo and rddid.
# Run from the module root: python dev/gen_new.py
import textwrap


def var(name, title, multi=False, perm=("numeric",), sug=None):
    s = f"    - name: {name}\n      title: {title}\n      type: {'Variables' if multi else 'Variable'}\n"
    if sug:
        s += "      suggested:\n" + "".join(f"          - {x}\n" for x in sug)
    s += "      permitted:\n" + "".join(f"          - {x}\n" for x in perm) + "\n"
    return s


def num(name, title, default, mn=None, mx=None, typ="Number"):
    s = f"    - name: {name}\n      title: {title}\n      type: {typ}\n      default: {default}\n"
    if mn is not None:
        s += f"      min: {mn}\n"
    if mx is not None:
        s += f"      max: {mx}\n"
    return s + "\n"


def lst(name, title, opts, default):
    s = f"    - name: {name}\n      title: {title}\n      type: List\n      options:\n"
    for n, t in opts:
        s += f"          - name: {n}\n            title: '{t}'\n"
    return s + f"      default: {default}\n\n"


def boo(name, title, default="false"):
    return f"    - name: {name}\n      title: {title}\n      type: Bool\n      default: {default}\n\n"


KERN = lst("kernel", "Kernel", [("triangular", "Triangular"), ("epanechnikov", "Epanechnikov"), ("uniform", "Uniform")], "triangular")
BW = lst("bwselect", "Bandwidth selector", [("mserd", "MSE-optimal, one common"), ("msetwo", "MSE-optimal, two different"),
                                            ("cerrd", "CER-optimal, one common"), ("certwo", "CER-optimal, two different")], "mserd")
VCE = lst("vce", "Variance estimator", [("nn", "Nearest neighbor"), ("hc0", "HC0"), ("hc1", "HC1"), ("hc2", "HC2"), ("hc3", "HC3")], "nn")
LEVEL = num("level", "Confidence level (%)", 95, 50, 99.9)
P = num("p", "Local polynomial order", 1, 0, 8, "Integer")
DONUT = num("donut", "Donut hole radius", 0, 0)


def head(name, title, menu, sub):
    return (f"---\nname: {name}\ntitle: {title}\njas: '1.2'\nversion: '1.0.0'\nmenuGroup: RDD\n"
            f"menuTitle: {menu}\nmenuSubtitle: {sub}\n\noptions:\n    - name: data\n      type: Data\n\n")


def box(label, name, single=True):
    return (f"          - type: TargetLayoutBox\n            label: {label}\n            children:\n"
            f"                - type: VariablesListBox\n                  name: {name}\n                  isTarget: true\n"
            + ("                  maxItemCount: 1\n" if single else ""))


def uhead(name, title, boxes):
    return (f"name: {name}\ntitle: {title}\njus: '3.0'\nstage: 0\ncompilerMode: tame\nchildren:\n"
            "    - type: VariableSupplier\n      persistentItems: false\n      stretchFactor: 1\n      children:\n"
            + "".join(boxes) + "    - type: LayoutBox\n      margin: large\n      children:\n")


def tb(name, label, fmt="number"):
    return f"        - type: TextBox\n          name: {name}\n          label: {label}\n          format: {fmt}\n"


def cb(name):
    return f"        - type: ComboBox\n          name: {name}\n"


def chk(name):
    return f"        - type: CheckBox\n          name: {name}\n"


def coll(label, items, collapsed="false"):
    s = (f"        - type: CollapseBox\n          label: {label}\n          collapsed: {collapsed}\n"
         "          children:\n              - type: LayoutBox\n                children:\n")
    for it in items:
        s += textwrap.indent(it, " " * 12)
    return s


def col(name, title, typ="number", fmt=None):
    s = f"          - name: {name}\n            title: '{title}'\n            type: {typ}\n"
    if fmt:
        s += f"            format: {fmt}\n"
    return s


def tbl(name, title, vis, cols, refs):
    return (f"    - name: {name}\n      title: {title}\n      type: Table\n      visible: ({vis})\n      refs:\n"
            + "".join(f"          - {r}\n" for r in refs) + "      columns:\n" + "".join(cols) + "\n")


def img(name, title, fun, vis, cw):
    return (f"    - name: {name}\n      title: {title}\n      type: Image\n      width: 640\n      height: 420\n"
            f"      renderFun: {fun}\n      visible: ({vis})\n      clearWith:\n"
            + "".join(f"          - {c}\n" for c in cw) + "\n")


NOTES = "    - name: notes\n      title: Notes\n      type: Html\n      visible: true\n\n"


def rhead(name, title):
    return f"---\nname: {name}\ntitle: {title}\njrs: '1.1'\n\nitems:\n" + NOTES


def write(name, a, r, u):
    for ext, t in (("a", a), ("r", r), ("u", u)):
        open(f"jamovi/{name}.{ext}.yaml", "w").write(t + ("...\n" if ext != "u" else ""))


ESTCOLS = [col("method", "Method", "text"), col("coef", "Estimate"), col("se", "Std. error"), col("z", "z"),
           col("p", "p", "number", "zto,pvalue"), col("lo", "CI lower"), col("hi", "CI upper")]
DESIGN = [col("item", "", "text"), col("left", "Left of cutoff", "text"), col("right", "Right of cutoff", "text")]
ROWCOLS = [col("label", "Row", "text"), col("coef", "Estimate"), col("se", "Robust s.e."),
           col("p", "Robust p", "number", "zto,pvalue"), col("lo", "CI lower"), col("hi", "CI upper")]

# ---------------- rdmc ----------------
a = (head("rdmc", "RD Multiple Cutoffs", "Multiple Cutoffs", "Cutoff-specific and pooled (rdmulti)")
     + var("outcome", "Outcome", sug=["continuous"]) + var("running", "Running variable (raw score)", sug=["continuous"])
     + var("cutVar", "Cutoff variable (cutoff faced by each observation)")
     + var("treatment", "Treatment received (fuzzy design, optional)", perm=("numeric", "factor"))
     + P + BW + KERN + VCE + LEVEL + boo("plot", "Cutoff-specific effects plot", "true"))
r = (rhead("rdmc", "RD Multiple Cutoffs")
     + tbl("est", "Cutoff-specific, weighted and pooled RD effects", "outcome",
           [col("label", "Cutoff", "text"), col("coef", "Conventional"), col("bc", "Bias-corrected"),
            col("p", "Robust p", "number", "zto,pvalue"), col("lo", "Robust CI lower"), col("hi", "Robust CI upper"),
            col("hl", "h (left)"), col("hr", "h (right)"), col("nl", "N (left)", "integer"),
            col("nr", "N (right)", "integer"), col("w", "Weight")], ["calonico2014", "cattaneo2021"])
     + img("effPlot", "Effects by cutoff", ".plotMc", "plot",
           ["outcome", "running", "cutVar", "treatment", "p", "bwselect", "kernel", "vce", "level"]))
u = (uhead("rdmc", "RD Multiple Cutoffs", [box("Outcome", "outcome"), box("Running variable (raw score)", "running"),
                                           box("Cutoff variable", "cutVar"), box("Treatment received (fuzzy RD)", "treatment")])
     + coll("Estimation", [tb("p", "Polynomial order (p)"), cb("bwselect"), cb("kernel"), cb("vce"),
                           tb("level", "Confidence level (%)")]) + chk("plot"))
write("rdmc", a, r, u)

# ---------------- rdhonest ----------------
a = (head("rdhonest", "RD Honest Confidence Intervals", "Honest CIs", "Armstrong and Kolesar (2020)")
     + var("outcome", "Outcome", sug=["continuous"]) + var("running", "Running variable", sug=["continuous"])
     + var("treatment", "Treatment received (fuzzy design, optional)", perm=("numeric", "factor"))
     + num("cutoff", "Cutoff", 0)
     + num("M", "Smoothness bound M on the second derivative (0 = rule of thumb)", 0, 0)
     + lst("optCriterion", "Bandwidth criterion", [("MSE", "Minimize worst-case MSE"), ("FLCI", "Minimize honest CI length"),
                                                   ("OCT", "Minimize optimal-conditional-test length")], "MSE")
     + lst("kernel", "Kernel", [("triangular", "Triangular"), ("epanechnikov", "Epanechnikov"), ("uniform", "Uniform")], "triangular")
     + lst("seMethod", "Standard errors", [("nn", "Nearest neighbor"), ("EHW", "Eicker-Huber-White")], "nn")
     + LEVEL + num("hManual", "Manual bandwidth (0 = optimal)", 0, 0))
r = (rhead("rdhonest", "RD Honest Confidence Intervals")
     + tbl("est", "Honest RD estimate", "outcome",
           [col("what", "", "text"), col("coef", "Estimate"), col("se", "Std. error"), col("bias", "Max. bias"),
            col("lo", "Honest CI lower"), col("hi", "Honest CI upper"), col("p", "p", "number", "zto,pvalue")],
           ["armstrong2020", "rdhonest"])
     + tbl("spec", "Specification", "outcome", [col("item", "", "text"), col("value", "Value", "text")], ["armstrong2020"]))
u = (uhead("rdhonest", "RD Honest Confidence Intervals", [box("Outcome", "outcome"), box("Running variable", "running"),
                                                           box("Treatment received (fuzzy RD)", "treatment")])
     + tb("cutoff", "Cutoff")
     + coll("Estimation", [tb("M", "Smoothness bound M (0 = rule of thumb)"), cb("optCriterion"), cb("kernel"),
                           cb("seMethod"), tb("level", "Confidence level (%)"), tb("hManual", "Manual bandwidth")]))
write("rdhonest", a, r, u)

# ---------------- rdgeo ----------------
a = (head("rdgeo", "RD Geographic / Two-Score Boundary", "Geographic / Two-Score", "Distance to a boundary")
     + var("outcome", "Outcome", sug=["continuous"])
     + var("treatment", "Treatment indicator (0/1; polyline boundary)", perm=("numeric", "factor"))
     + var("x1", "Coordinate / score 1", sug=["continuous"]) + var("x2", "Coordinate / score 2", sug=["continuous"])
     + var("bx", "Boundary vertex, coordinate 1 (polyline)") + var("by", "Boundary vertex, coordinate 2 (polyline)")
     + var("cluster", "Cluster (optional)", perm=("factor", "id", "numeric"))
     + lst("boundary", "Boundary", [("polyline", "Polyline from vertex variables"),
                                    ("both", "Two scores: treated if both reach their cutoffs"),
                                    ("either", "Two scores: treated if either reaches its cutoff")], "polyline")
     + num("c1", "Cutoff for score 1", 0) + num("c2", "Cutoff for score 2", 0)
     + P + BW + KERN + VCE + LEVEL + DONUT + boo("plot", "Map of the sample", "true"))
r = (rhead("rdgeo", "RD Geographic / Two-Score Boundary")
     + tbl("design", "Design and sample", "outcome", DESIGN, ["calonico2014", "cattaneo2022"])
     + tbl("est", "RD effect at the boundary (signed distance)", "outcome", ESTCOLS, ["calonico2014"])
     + img("mapPlot", "Sample and boundary", ".plotGeo", "plot",
           ["outcome", "treatment", "x1", "x2", "bx", "by", "boundary", "c1", "c2"]))
u = (uhead("rdgeo", "RD Geographic / Two-Score Boundary",
           [box("Outcome", "outcome"), box("Treatment indicator", "treatment"), box("Coordinate / score 1", "x1"),
            box("Coordinate / score 2", "x2"), box("Boundary vertices, coord. 1", "bx"),
            box("Boundary vertices, coord. 2", "by"), box("Cluster", "cluster")])
     + cb("boundary") + tb("c1", "Cutoff for score 1") + tb("c2", "Cutoff for score 2")
     + coll("Estimation", [tb("p", "Polynomial order (p)"), cb("bwselect"), cb("kernel"), cb("vce"),
                           tb("level", "Confidence level (%)"), tb("donut", "Donut hole radius")]) + chk("plot"))
write("rdgeo", a, r, u)

# ---------------- rddid ----------------
a = (head("rddid", "RD Difference-in-Discontinuities", "Diff-in-Discontinuities", "Grembi et al. (2016)")
     + var("outcome", "Outcome", sug=["continuous"]) + var("running", "Running variable", sug=["continuous"])
     + var("period", "Period (two values; the larger or later one is post)", perm=("numeric", "factor"))
     + var("unit", "Unit identifier (optional; panel differencing)", perm=("factor", "id", "numeric"))
     + num("cutoff", "Cutoff", 0) + P + BW + KERN + VCE + LEVEL)
r = (rhead("rddid", "RD Difference-in-Discontinuities")
     + tbl("est", "Discontinuity before, after and the difference", "outcome", ROWCOLS, ["calonico2014", "grembi2016"])
     + tbl("design", "Bandwidths and sample", "outcome", [col("item", "", "text"), col("value", "Value", "text")], ["calonico2014"]))
u = (uhead("rddid", "RD Difference-in-Discontinuities",
           [box("Outcome", "outcome"), box("Running variable", "running"), box("Period (two values)", "period"),
            box("Unit (panel, optional)", "unit")])
     + tb("cutoff", "Cutoff")
     + coll("Estimation", [tb("p", "Polynomial order (p)"), cb("bwselect"), cb("kernel"), cb("vce"),
                           tb("level", "Confidence level (%)")]))
write("rddid", a, r, u)
