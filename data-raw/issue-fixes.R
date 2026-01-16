library(tidyverse)
library(ellmer)
library(cli)

# Read the current explanations CSV
vera_explanations <- read_csv(
  "inst/extdata/vera_explanations.csv",
  show_col_types = FALSE
)

# Create a chat object for generating user-friendly fixes
chat <- chat_claude(
system_prompt = "You are an expert at helping users fix PDF accessibility issues.
Your task is to provide clear, actionable instructions for how to fix specific accessibility problems.

IMPORTANT CONTEXT: Users are creating PDFs using Quarto with either LaTeX or Typst as the PDF engine.
They are NOT editing PDFs after the fact in software like Adobe Acrobat.
The fixes need to happen in the SOURCE document (the .qmd file) or in Quarto's YAML configuration before generating the PDF.

Your instructions should:
- Be concise (2-3 sentences maximum)
- Use plain language that anyone can understand
- Focus on what needs to change in the Quarto source document (.qmd file) or YAML front matter
- Keep instructions generic and applicable to BOTH LaTeX and Typst users
- DO NOT mention specific LaTeX packages (like hyperref, pdfmanagement-testphase, etc.)
- DO NOT mention specific Typst functions or packages
- DO NOT mention PDF editing software like Adobe Acrobat, PDF editors, or similar tools
- Focus on Quarto-level configuration (YAML options) and content changes, not PDF engine internals
- If a fix requires PDF engine-specific configuration, simply say it may require additional configuration in the PDF engine settings"
)

# Function to generate a user-friendly fix with error handling
generate_fix <- function(description, message, user_friendly_message, chat_obj) {
  prompt <- glue::glue(
    "Here is information about a PDF accessibility issue:

    Technical description: {description}

    Technical error message: {message}

    User-friendly explanation of the issue: {user_friendly_message}

    Please provide clear, actionable instructions for how to fix this issue.
    Remember: the user is creating PDFs using Quarto with either LaTeX or Typst as the PDF engine.
    Focus on what needs to change in the .qmd source file or Quarto YAML configuration.
    Keep the instructions generic - do NOT mention specific LaTeX packages or Typst functions.
    Focus on Quarto-level solutions that work regardless of PDF engine.
    Return ONLY the fix instructions, nothing else."
  )

  tryCatch(
    {
      response <- chat_obj$chat(prompt)
      as.character(response)
    },
    error = function(e) {
      cli_warn("Error generating fix for: {description}\n{e$message}")
      NA_character_
    }
  )
}

# Add user-friendly fixes
n_issues <- nrow(vera_explanations)
cli_alert_info("Generating user-friendly fixes for {n_issues} issues...")

vera_explanations_with_fixes <- vera_explanations |>
  mutate(
    user_friendly_fix = pmap_chr(
      list(description, message, user_friendly_message),
      \(description, message, user_friendly_message) {
        row_num <- which(vera_explanations$description == description)[1]
        if (row_num %% 10 == 0 || row_num == 1) {
          cli_progress_message("Processing row {row_num} of {n_issues}")
        }
        generate_fix(description, message, user_friendly_message, chat)
      }
    )
  )

cli_alert_success("Fix generation complete!")

# Preview the results
vera_explanations_with_fixes |>
  select(rule_id, user_friendly_message, user_friendly_fix) |>
  print(n = 5)

# Save to a new file (not overwriting existing files)
write_csv(
  vera_explanations_with_fixes,
  "data-raw/vera_explanations_with_fixes.csv"
)

cli_alert_success("File saved to {.file data-raw/vera_explanations_with_fixes.csv}")
