# Writes help/<analysis>.md from the in-app Method notes (R/guide.R), so the repository help matches the module.
# Run from the module root: Rscript dev/make_help.R
source("R/guide.R")
md <- function(x) {
    x <- gsub("<h2>(.*?)</h2>", "# \\1\n\n", x)
    x <- gsub("<h3>(.*?)</h3>", "\n## \\1\n\n", x)
    x <- gsub("<li>", "- ", x, fixed = TRUE); x <- gsub("</li>", "\n", x, fixed = TRUE)
    x <- gsub("</?(ul|p)>", "\n", x)
    x <- gsub("<[^>]+>", "", x)
    x <- gsub("&gt;", ">", x, fixed = TRUE); x <- gsub("&lt;", "<", x, fixed = TRUE); x <- gsub("&times;", "x", x, fixed = TRUE)
    gsub("\n{3,}", "\n\n", x)
}
for (k in c("rd", "rddens", "rdcov", "rdsens", "rdlr", "rdmc", "rdhonest", "rdgeo", "rddid", "rdhte", "rdcmp"))
    writeLines(trimws(md(rd_notes_html(k))), file.path("help", paste0(k, ".md")))
cat("help files written\n")
