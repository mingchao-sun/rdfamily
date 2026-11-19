# Generates the .a/.r/.u.yaml files of rdpower (RD power, minimum detectable effect and sample size).
# Run from the module root: python dev/gen_power.py
import sys
sys.argv = ["x"]
NL = "\n"


def q(s):
    return "'" + s.replace("'", "''") + "'"


def var(name, title, multi=False, perm=("numeric",), sug=None):
    s = f"    - name: {name}{NL}      title: {q(title)}{NL}      type: {'Variables' if multi else 'Variable'}{NL}"
    if sug:
        s += f"      suggested:{NL}" + "".join(f"          - {x}{NL}" for x in sug)
    s += f"      permitted:{NL}" + "".join(f"          - {x}{NL}" for x in perm) + NL
    return s


def num(name, title, default, mn=None, mx=None, typ="Number"):
    s = f"    - name: {name}{NL}      title: {q(title)}{NL}      type: {typ}{NL}      default: {default}{NL}"
    if mn is not None:
        s += f"      min: {mn}{NL}"
    if mx is not None:
        s += f"      max: {mx}{NL}"
    return s + NL


def lst(name, title, opts, default):
    s = f"    - name: {name}{NL}      title: {q(title)}{NL}      type: List{NL}      options:{NL}"
    for n, t in opts:
        s += f"          - name: {n}{NL}            title: {q(t)}{NL}"
    return s + f"      default: {default}{NL}{NL}"


def boo(name, title, default="false"):
    return f"    - name: {name}{NL}      title: {q(title)}{NL}      type: Bool{NL}      default: {default}{NL}{NL}"


OPTS = "outcome, running, treatment, covs, cutoff, mode, tau, alpha, beta, p, kernel, bwselect, vce"

a = (f"---{NL}name: rdpower{NL}title: 'RD Power and Sample Size'{NL}jas: '1.2'{NL}version: '1.0.0'{NL}menuGroup: RDD{NL}"
     f"menuTitle: 'RD Power and Sample Size'{NL}menuSubtitle: 'Power, minimum detectable effect and sample size of an RD design'{NL}{NL}options:{NL}    - name: data{NL}      type: Data{NL}{NL}")
a += var("outcome", "Outcome") + var("running", "Running variable") + var("treatment", "Treatment received (fuzzy RD, optional)", False, ("numeric",), ("continuous",))
a += var("covs", "Covariates (optional)", True, ("numeric",), ("continuous",))
a += num("cutoff", "Cutoff", 0)
a += lst("mode", "Calculate", [("power", "Power for an effect"), ("mde", "Minimum detectable effect"), ("sampsi", "Sample size for a power")], "power")
a += num("tau", "Effect to detect (outcome units)", 1) + num("alpha", "Significance level", 0.05, 0.0001, 0.5) + num("beta", "Target power", 0.8, 0.5, 0.9999)
a += num("p", "Local polynomial order", 1, 0, 8, "Integer")
a += lst("kernel", "Kernel", [("triangular", "Triangular"), ("epanechnikov", "Epanechnikov"), ("uniform", "Uniform")], "triangular")
a += lst("bwselect", "Bandwidth selector", [("mserd", "MSE-optimal, one common"), ("msetwo", "MSE-optimal, two different"), ("cerrd", "CER-optimal, one common"), ("certwo", "CER-optimal, two different")], "mserd")
a += lst("vce", "Variance estimator", [("nn", "Nearest neighbor"), ("hc0", "HC0"), ("hc1", "HC1"), ("hc2", "HC2"), ("hc3", "HC3")], "nn")
a += boo("showHelp", "Method notes") + boo("showGuide", "Data and setup guide") + "..." + NL

r = (f"---{NL}name: rdpower{NL}title: 'RD Power and Sample Size'{NL}jrs: '1.1'{NL}{NL}items:{NL}"
     f"    - name: guide{NL}      title: Data and setup guide{NL}      type: Html{NL}      visible: (showGuide){NL}{NL}"
     f"    - name: helpText{NL}      title: Method notes{NL}      type: Html{NL}      visible: (showHelp){NL}{NL}"
     f"    - name: notes{NL}      title: Notes{NL}      type: Html{NL}      visible: true{NL}{NL}")


def col(name, title, typ, extra=""):
    return f"        - name: {name}{NL}          title: {q(title)}{NL}          type: {typ}{NL}" + (extra + NL if extra else "")


def tbl(name, title, cols, visible=None):
    s = f"    - name: {name}{NL}      title: {q(title)}{NL}      type: Table{NL}      rows: 0{NL}"
    if visible:
        s += f"      visible: {visible}{NL}"
    return s + f"      clearWith: [{OPTS}]{NL}      columns:{NL}" + "".join(cols) + NL


r += tbl("design", "Design used for the calculation", [col("item", "", "text"), col("left", "Left of the cutoff", "number"), col("right", "Right of the cutoff", "number")])
r += tbl("res", "Result", [col("item", "", "text"), col("rbc", "Robust bias-corrected", "number"), col("conv", "Conventional", "number")])
r += tbl("curve", "Power against other effects", [col("effect", "Effect", "number"), col("rbc", "Power (robust bias-corrected)", "number"), col("conv", "Power (conventional)", "number")], "(mode:power)")
r += f"refs:{NL}    - cattaneo2019power{NL}    - calonico2014{NL}...{NL}"


def box(label, name, single=True):
    s = f"          - type: TargetLayoutBox{NL}            label: {q(label)}{NL}            children:{NL}                - type: VariablesListBox{NL}                  name: {name}{NL}                  isTarget: true{NL}                  height: small{NL}"
    if single:
        s += f"                  maxItemCount: 1{NL}"
    return s


def tb(name, label, fmt="number"):
    return f"          - type: TextBox{NL}            name: {name}{NL}            label: {q(label)}{NL}            format: {fmt}{NL}"


def cb(name, label=None):
    return f"          - type: CheckBox{NL}            name: {name}{NL}" + (f"            label: {q(label)}{NL}" if label else "")


def cmb(name):
    return f"          - type: ComboBox{NL}            name: {name}{NL}"


def collapse(label, body, collapsed=True):
    return f"    - type: CollapseBox{NL}      label: {q(label)}{NL}      collapsed: {str(collapsed).lower()}{NL}      children:{NL}" + body


u = (f"title: 'RD Power and Sample Size'{NL}name: rdpower{NL}jus: '3.0'{NL}stage: 0{NL}compilerMode: tame{NL}children:{NL}"
     f"    - type: VariableSupplier{NL}      persistentItems: false{NL}      stretchFactor: 1{NL}      children:{NL}")
u += box("Outcome", "outcome") + box("Running variable", "running") + box("Treatment received (fuzzy RD, optional)", "treatment") + box("Covariates (optional)", "covs", False)
u += collapse("Design", tb("cutoff", "Cutoff") + cmb("mode") + tb("tau", "Effect to detect (outcome units)") + tb("alpha", "Significance level") + tb("beta", "Target power"), False)
u += collapse("Local polynomial", tb("p", "Local polynomial order") + cmb("kernel") + cmb("bwselect") + cmb("vce"))
u += collapse("Output", cb("showHelp", "Method notes") + cb("showGuide", "Data and setup guide"))

for ext, t in (("a", a), ("r", r), ("u", u)):
    with open(f"jamovi/rdpower.{ext}.yaml", "w", encoding="utf-8", newline="") as f:
        f.write(t)
print("written")
