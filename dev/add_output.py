# Post-processes the yaml files of every analysis (idempotent; run from the module root):
#  * flattens the u.yaml layout so that collapse boxes span the full page width, all collapsed by default
#  * adds the Output section with the options "Method notes" and "Data and setup guide"
#  * adds the matching options and result items
# Run after dev/gen_new.py if that is re-run.
import re

NAMES = ["rd", "rddens", "rdcov", "rdsens", "rdlr", "rdmc", "rdhonest", "rdgeo", "rddid", "rdhte", "rdcmp"]

OPTS = """
    - name: showHelp
      title: Method notes
      type: Bool
      default: false

    - name: showGuide
      title: Data and setup guide
      type: Bool
      default: false
"""

ITEMS = """    - name: guide
      title: Data and setup guide
      type: Html
      visible: (showGuide)

    - name: helpText
      title: Method notes
      type: Html
      visible: (showHelp)

"""

OUTPUT_UI = """    - type: CollapseBox
      label: Output
      collapsed: true
      children:
          - type: CheckBox
            name: showHelp
            label: Method notes
          - type: CheckBox
            name: showGuide
            label: Data and setup guide
"""

for n in NAMES:
    # options
    p = f"jamovi/{n}.a.yaml"
    s = open(p).read()
    if "name: showHelp" not in s:
        s = s.rstrip()
        assert s.endswith("..."), p
        s = s[:-3].rstrip("\n") + "\n" + OPTS + "...\n"
        open(p, "w").write(s)
    # results
    p = f"jamovi/{n}.r.yaml"
    s = open(p).read()
    if "name: helpText" not in s:
        s = s.replace("items:\n", "items:\n" + ITEMS, 1)
        open(p, "w").write(s)
    # ui
    p = f"jamovi/{n}.u.yaml"
    s = open(p).read()
    wrapper = "    - type: LayoutBox\n      margin: large\n      children:\n"
    if wrapper in s:
        head, tail = s.split(wrapper, 1)
        tail = "".join(l[4:] if l.startswith("    ") else l for l in tail.splitlines(True))
        s = head + tail
    s = s.replace("collapsed: false", "collapsed: true")
    if "name: showGuide" not in s:
        s = s.rstrip("\n") + "\n" + OUTPUT_UI
    open(p, "w").write(s)

    # analysis class: show the texts first thing in .run
    p = f"R/{n}.b.R"
    s = open(p).read()
    call = f'            rd_show_text(self$results, opts, "{n}")\n'
    if "rd_show_text" not in s:
        marker = "        .run = function() {\n            opts <- self$options\n"
        assert marker in s, p
        s = s.replace(marker, marker + call, 1)
        open(p, "w").write(s)
print("ok")
