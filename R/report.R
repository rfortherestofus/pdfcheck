#' @title Accessibility report
#'
#' @description
#' Generates an HTML report on accessibility for a given PDF.
#'
#' @param file PDF file to check.
#' @param profile The validation profile to use. Default to `"ua1"`.
#' @param output_file Path for the HTML report. If `NULL`, creates a temp file.
#' @param open Whether to automatically open the report in browser. Default `TRUE`.
#'
#' @return Path to the generated HTML report (invisibly)
#'
#' @import glue dplyr htmltools htmlwidgets utils tibble jsonlite
#'
#' @export
accessibility_report <- function(
  file,
  profile = "ua1",
  output_file = tempfile(fileext = ".html"),
  open = TRUE
) {
  json <- verapdf(file = file, profile = profile)
  verapdf_version <- get_verapdf_version(json)
  is_compliant <- is_pdf_compliant(json, from_json = TRUE)
  results <- json$report$jobs$validationResult[[1]]
  n_passed_rules <- results$details$passedRules
  n_failed_rules <- results$details$failedRules
  failed_rules <- results$details$ruleSummaries

  # Load user-friendly explanations
  explanations_file <- system.file(
    "extdata",
    "vera_explanations.csv",
    package = "pdfcheck",
    mustWork = TRUE
  )
  explanations <- read.csv(explanations_file, stringsAsFactors = FALSE)

  status_class <- if (is_compliant) "compliant" else "non-compliant"

  failed_rules_df <- tibble::tibble()

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

        rule_key <- paste0(spec, "|", clause, "|", test_num)

        if (is.null(aggregated_rules[[rule_key]])) {
          aggregated_rules[[rule_key]] <- list(
            specification = spec,
            clause = clause,
            testNumber = test_num,
            description = desc
          )
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

      how_to_fix <- if (
        length(explanation_idx) > 0 &&
          "user_friendly_fix" %in% names(explanations) &&
          !is.na(explanations$user_friendly_fix[explanation_idx[1]])
      ) {
        explanations$user_friendly_fix[explanation_idx[1]]
      } else {
        "No fix information available."
      }

      failed_rules_df <- failed_rules_df |>
        bind_rows(data.frame(
          rule_id = c(rule_id),
          spec = c(spec),
          clause = c(clause),
          description = c(fr$description),
          user_message = c(user_message),
          how_to_fix = c(how_to_fix)
        ))
    }
  }

  if (nrow(failed_rules_df) > 0) {
    # Generate card HTML for each issue
    cards_html <- failed_rules_df |>
      mutate(
        iso_clean = gsub("ISO ", "", spec),
        # Escape special characters for HTML attributes
        rule_id_escaped = gsub('"', '&quot;', rule_id),
        user_message_escaped = gsub('"', '&quot;', user_message),
        iso_clean_escaped = gsub('"', '&quot;', iso_clean),
        clause_escaped = gsub('"', '&quot;', clause),
        description_escaped = gsub('"', '&quot;', description),
        card_html = paste0(
          '<div class="issue-card">',
          '<div class="issue-card-header">',
          '<div class="issue-card-label">',
          '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>',
          'Issue</div>',
          '<div class="issue-card-message">',
          htmltools::htmlEscape(user_message),
          '</div>',
          '</div>',
          '<div class="issue-card-body">',
          '<div class="issue-card-label">',
          '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path></svg>',
          'Fix</div>',
          '<div class="issue-card-fix">',
          htmltools::htmlEscape(how_to_fix),
          '</div>',
          '</div>',
          '<div class="issue-card-footer">',
          '<button class="more-info-btn" ',
          'data-rule-id="',
          rule_id_escaped,
          '" ',
          'data-explanation="',
          user_message_escaped,
          '" ',
          'data-iso="',
          iso_clean_escaped,
          '" ',
          'data-clause="',
          clause_escaped,
          '" ',
          'data-verapdf="',
          description_escaped,
          '">',
          'More info <span class="arrow">&rarr;</span>',
          '</button>',
          '</div>',
          '</div>'
        )
      ) |>
      pull(card_html) |>
      paste0(collapse = "\n")

    cards_html <- paste0(
      '<div class="issue-cards-container">',
      cards_html,
      '</div>'
    )
  } else {
    cards_html <- ""
  }

  css <- system.file("report", "style.css", package = "pdfcheck") |>
    readLines() |>
    paste0(collapse = "\n")

  if (!is_compliant) {
    issue_section <- '
    <br>
    <h2 class="section-title">Issues Requiring Attention</h2>
    <br>
'
  } else {
    issue_section <- ""
  }

  modal_css <- '
    /* Issue Cards */
    .issue-cards-container {
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .issue-card {
      background: #f9fafb;
      border-radius: 12px;
      box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
      border: 1px solid rgba(17, 24, 39, 0.05);
      overflow: hidden;
      font-family: "Inter", Roboto, Arial, sans-serif;
    }
    .issue-card-header {
      padding: 24px 24px 20px 24px;
    }
    .issue-card-label {
      font-size: 0.75em;
      font-weight: 600;
      color: #6b7280;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .issue-card-label svg {
      flex-shrink: 0;
    }
    .issue-card-message {
      font-size: 1em;
      font-weight: 400;
      color: #111827;
      line-height: 1.65;
    }
    .issue-card-body {
      padding: 24px;
      border-top: 1px solid rgba(17, 24, 39, 0.05);
    }
    .issue-card-fix {
      font-size: 0.95em;
      color: #4b5563;
      line-height: 1.65;
    }
    .issue-card-footer {
      padding: 24px;
      border-top: 1px solid rgba(17, 24, 39, 0.05);
    }
    .more-info-btn {
      background: transparent;
      cursor: pointer;
      color: #6b7280;
      font-family: "Inter", Roboto, Arial, sans-serif;
      font-size: 0.8em;
      font-weight: 500;
      padding: 6px 12px;
      border-radius: 9999px;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      border: 1px solid #d1d5db;
      transition: all 0.2s;
    }
    .more-info-btn:hover {
      background-color: #f3f4f6;
      color: #4b5563;
      border-color: #9ca3af;
    }
    .more-info-btn .arrow {
      transition: transform 0.2s;
    }
    .more-info-btn:hover .arrow {
      transform: translateX(3px);
    }

    /* Modal */
    .modal-overlay {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.5);
      z-index: 1000;
      justify-content: center;
      align-items: center;
    }
    .modal-overlay.active {
      display: flex;
    }
    .modal-content {
      background: white;
      border-radius: 12px;
      max-width: 600px;
      width: 90%;
      max-height: 80vh;
      overflow-y: auto;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    }
    .modal-header {
      padding: 20px 24px;
      border-bottom: 1px solid #e9ecef;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .modal-header h3 {
      margin: 0;
      font-size: 1.25em;
      color: #333;
    }
    .modal-close {
      background: none;
      border: none;
      font-size: 1.5em;
      cursor: pointer;
      color: #666;
      padding: 0;
      line-height: 1;
    }
    .modal-close:hover {
      color: #333;
    }
    .modal-body {
      padding: 24px;
    }
    .modal-body p {
      margin: 0 0 16px 0;
      line-height: 1.6;
    }
    .modal-body p:last-child {
      margin-bottom: 0;
    }
    .modal-body strong {
      color: #333;
    }
    .modal-intro {
      color: #666;
      font-style: italic;
      border-bottom: 1px solid #e9ecef;
      padding-bottom: 16px;
      margin-bottom: 16px;
    }
  '

  modal_js <- '
    function closeModal() {
      document.getElementById("details-modal").classList.remove("active");
    }

    document.addEventListener("click", function(e) {
      const btn = e.target.closest(".more-info-btn");
      if (btn) {
        document.getElementById("modal-rule-id").textContent = btn.dataset.ruleId || "";
        document.getElementById("modal-explanation").textContent = btn.dataset.explanation || "";
        document.getElementById("modal-iso").textContent = btn.dataset.iso || "";
        document.getElementById("modal-clause").textContent = btn.dataset.clause || "";
        document.getElementById("modal-verapdf").textContent = btn.dataset.verapdf || "";
        document.getElementById("details-modal").classList.add("active");
      }
    });

    document.addEventListener("keydown", function(e) {
      if (e.key === "Escape") closeModal();
    });
  '

  html_content <- glue(
    '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>pdfcheck | PDF Accessibility Report</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap" rel="stylesheet">
    <style>{css}</style>
    <style>{modal_css}</style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>PDF Accessibility Report</h1>
            <div class="filename">{basename(file)}</div>
        </div>

        <div class="content">
            <div class="status-banner {status_class}">
                {status_class}
            </div>

            <div class="meta-info">
                <strong>Validation profile:</strong> {toupper(profile)} |
                <strong>VeraPDF version:</strong> {verapdf_version} |
                <strong>Report generated:</strong> {sub("AM", "am", sub("PM", "pm", format(Sys.time(), "%B %d, %Y at %I:%M%p")))}
            </div>

            <div class="stats-grid">
                <div class="stat-card passed">
                    <div class="stat-number">{n_passed_rules}</div>
                    <div class="stat-label">Passed Rules</div>
                </div>
                <div class="stat-card failed">
                    <div class="stat-number">{n_failed_rules}</div>
                    <div class="stat-label">Failed Rules</div>
                </div>
            </div>

            {issue_section}
            {cards_html}
        </div>

        <div class="footer">
            Generated by <a href="https://pdfcheck.org" target="_blank"><code>pdfcheck</code></a> | <a href="https://rfortherestofus.com/" target="_blank">R for the Rest of Us</a>
        </div>
    </div>

    <!-- Details Modal -->
    <div id="details-modal" class="modal-overlay" onclick="if(event.target === this) closeModal()">
        <div class="modal-content">
            <div class="modal-header">
                <h3>Technical Details</h3>
                <button class="modal-close" onclick="closeModal()" aria-label="Close modal">&times;</button>
            </div>
            <div class="modal-body">
                <p class="modal-intro">The following technical details reference the PDF/UA standard and veraPDF validation rules. This information is intended for developers and accessibility specialists.</p>
                <p><strong>Rule ID:</strong> <span id="modal-rule-id"></span></p>
                <p><strong>Explanation:</strong> <span id="modal-explanation"></span></p>
                <p><strong>ISO:</strong> <span id="modal-iso"></span></p>
                <p><strong>Clause:</strong> <span id="modal-clause"></span></p>
                <p><strong>veraPDF Issue:</strong> <span id="modal-verapdf"></span></p>
            </div>
        </div>
    </div>

    <script>{modal_js}</script>
</body>
</html>'
  )

  writeLines(html_content, output_file)

  if (open) {
    browseURL(output_file)
  }

  invisible(output_file)
}
