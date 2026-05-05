.read_report_asset <- function(...) {
  system.file("report", ..., package = "pdfcheck", mustWork = TRUE) |>
    readLines(warn = FALSE) |>
    paste0(collapse = "\n")
}

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
    issue_card_template <- .read_report_asset("issue-card.html")
    issue_cards_container_template <- .read_report_asset(
      "issue-cards-container.html"
    )

    # Generate card HTML for each issue
    cards_data <- failed_rules_df |>
      mutate(
        iso_clean = gsub("ISO ", "", spec),
        # Escape special characters for HTML attributes
        rule_id_escaped = gsub('"', '&quot;', rule_id),
        user_message_escaped = gsub('"', '&quot;', user_message),
        iso_clean_escaped = gsub('"', '&quot;', iso_clean),
        clause_escaped = gsub('"', '&quot;', clause),
        description_escaped = gsub('"', '&quot;', description),
        user_message_html = htmltools::htmlEscape(user_message),
        how_to_fix_html = htmltools::htmlEscape(how_to_fix)
      )

    issue_cards_html <- glue::glue_data(
      cards_data,
      issue_card_template,
      .trim = FALSE
    ) |>
      as.character() |>
      paste0(collapse = "\n")

    cards_html <- glue::glue(issue_cards_container_template, .trim = FALSE)
  } else {
    cards_html <- ""
  }

  css <- .read_report_asset("style.css")
  modal_css <- .read_report_asset("modal.css")
  modal_js <- .read_report_asset("modal.js")
  report_template <- .read_report_asset("report-template.html")

  issue_section <- if (!is_compliant) {
    .read_report_asset("issue-section.html")
  } else {
    ""
  }

  filename <- basename(file)
  profile_upper <- toupper(profile)
  report_generated <- sub(
    "AM",
    "am",
    sub("PM", "pm", format(Sys.time(), "%B %d, %Y at %I:%M%p"))
  )

  html_content <- glue::glue(report_template, .trim = FALSE)

  writeLines(html_content, output_file)

  if (open) {
    browseURL(output_file)
  }

  invisible(output_file)
}
