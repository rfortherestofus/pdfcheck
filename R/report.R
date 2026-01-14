#' @title Accessibility report
#'
#' @description
#' Generates an HTML report on accessibility for a given PDF.
#'
#' @param file PDF file to check.
#' @param profile The validation profile to use. Default to `"ua1"` (recommended).
#' @param output_file Path for the HTML report. If NULL, creates a temp file.
#' @param open Whether to automatically open the report in browser. Default TRUE.
#'
#' @return Path to the generated HTML report (invisibly)
#'
#' @import glue utils
#'
#' @export
accessibility_report <- function(
  file,
  profile = "ua1",
  output_file = NULL,
  open = TRUE
) {
  json <- verapdf(file = file, profile = profile)
  verapdf_version <- get_verapdf_version(json)
  is_compliant <- is_pdf_compliant(json, from_json = TRUE)
  results <- json$report$jobs$validationResult[[1]]
  n_passed_rules <- results$details$passedRules
  n_passed_checks <- results$details$passedChecks
  n_failed_rules <- results$details$failedRules
  n_failed_check <- results$details$failedChecks
  failed_rules <- results$details$ruleSummaries

  # Load user-friendly explanations
  explanations_file <- system.file(
    "extdata",
    "vera_explanations.csv",
    package = "pdfcheck",
    mustWork = TRUE
  )
  explanations <- read.csv(explanations_file, stringsAsFactors = FALSE)

  if (is.null(output_file)) {
    output_file <- tempfile(fileext = ".html")
  }

  status_class <- if (is_compliant) "compliant" else "non-compliant"

  failed_rules_rows <- ""
  if (length(failed_rules) > 0) {
    # Aggregate failed rules to avoid duplicates
    # Group by spec, clause, testNumber and sum failedChecks
    aggregated_rules <- list()

    for (i in seq_along(failed_rules)) {
      fr <- failed_rules[[i]]

      # Each element in failed_rules can contain vectors
      # We need to iterate over all elements in those vectors
      n_checks <- length(fr$failedChecks)

      for (j in seq_len(n_checks)) {
        # Extract j-th element from each field
        spec <- fr$specification[j]
        clause <- fr$clause[j]
        test_num <- fr$testNumber[j]
        desc <- fr$description[j]
        checks <- fr$failedChecks[j]

        # Create unique key for this rule
        rule_key <- paste0(spec, "|", clause, "|", test_num)

        if (is.null(aggregated_rules[[rule_key]])) {
          # First time seeing this rule
          aggregated_rules[[rule_key]] <- list(
            specification = spec,
            clause = clause,
            testNumber = test_num,
            description = desc,
            failedChecks = checks
          )
        } else {
          # Already seen this rule, add to the count
          aggregated_rules[[rule_key]]$failedChecks <-
            aggregated_rules[[rule_key]]$failedChecks + checks
        }
      }
    }

    # Now create rows from aggregated data
    for (rule_key in names(aggregated_rules)) {
      fr <- aggregated_rules[[rule_key]]

      spec <- fr$specification
      clause <- fr$clause
      test_num <- fr$testNumber

      # Convert specification format from "ISO 14289-1:2014" to "ISO_14289_1"
      spec_normalized <- gsub(":.*", "", spec) # Remove version part first
      spec_normalized <- gsub("[ -]", "_", spec_normalized) # Replace spaces and dashes with underscores

      # Construct rule_id to match against CSV
      # Format: ISO_14289_1-7.1.3
      rule_id <- paste0(spec_normalized, "-", clause, ".", test_num)

      # Find matching user-friendly explanation by rule_id
      explanation_idx <- which(explanations$rule_id == rule_id)

      user_message <- if (length(explanation_idx) > 0) {
        explanations$user_friendly_message[explanation_idx[1]]
      } else {
        "No user-friendly explanation available."
      }

      failed_rules_rows <- paste0(
        failed_rules_rows,
        sprintf(
          '
                    <tr class="issue-row">
                        <td class="spec-cell">%s</td>
                        <td class="clause-cell">%s</td>
                        <td class="desc-cell">%s</td>
                        <td class="explanation-cell">%s</td>
                        <td class="count-cell">%d</td>
                    </tr>',
          spec,
          clause,
          fr$description,
          user_message,
          fr$failedChecks
        )
      )
    }
  } else {
    failed_rules_rows <- '<tr><td colspan="5" class="no-issues">No issues found</td></tr>'
  }

  css <- system.file("report", "style.css", package = "pdfcheck") |>
    readLines() |>
    paste0(collapse = "\n")

  issues_section <- ""
  if (!is_compliant) {
    issues_section <- sprintf(
      '
            <br>

            <h2 class="section-title">Issues requiring attention</h2>
            
            <table class="issues-table">
                <thead>
                    <tr>
                        <th>Specification</th>
                        <th>Clause</th>
                        <th>Description</th>
                        <th>Explanation</th>
                        <th>Failed Checks</th>
                    </tr>
                </thead>
                <tbody>%s
                </tbody>
            </table>',
      failed_rules_rows |> paste0(collapse = "\n")
    )
  }

  html_content <- sprintf(
    '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>pdfcheck | PDF Accessibility Report</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap" rel="stylesheet">
    <style>
        %s
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>PDF accessibility report</h1>
            <div class="filename">%s</div>
        </div>
        
        <div class="content">
            <div class="status-banner %s">
                %s
            </div>
            
            <div class="meta-info">
                <strong>Validation profile:</strong> %s | 
                <strong>VeraPDF version:</strong> %s | 
                <strong>Report generated:</strong> %s
            </div>
            
            <div class="stats-grid">
                <div class="stat-card passed">
                    <div class="stat-number">%d</div>
                    <div class="stat-label">Passed Rules</div>
                </div>
                <div class="stat-card passed">
                    <div class="stat-number">%d</div>
                    <div class="stat-label">Passed Checks</div>
                </div>
                <div class="stat-card failed">
                    <div class="stat-number">%d</div>
                    <div class="stat-label">Failed Rules</div>
                </div>
                <div class="stat-card failed">
                    <div class="stat-number">%d</div>
                    <div class="stat-label">Failed Checks</div>
                </div>
            </div>
            
            %s
        </div>
        
        <div class="footer">
            Generated by <a href="https://github.com/rfortherestofus/pdfcheck/" target="_blank"><code>{pdfcheck}</code></a> | <a href="https://rfortherestofus.com/" target="_blank">R for the Rest of Us</a>
        </div>
    </div>
</body>
</html>',
    css,
    basename(file),
    status_class,
    status_class,
    toupper(profile),
    verapdf_version,
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    n_passed_rules,
    n_passed_checks,
    n_failed_rules,
    n_failed_check,
    issues_section
  )

  writeLines(html_content, output_file)

  if (open) {
    browseURL(output_file)
  }

  invisible(output_file)
}
