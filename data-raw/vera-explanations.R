library(tidyverse)
library(xml2)

# Download and parse veraPDF PDFUA-1 validation rules
url <- "https://raw.githubusercontent.com/veraPDF/veraPDF-library/5c54577c665ec0b855d3000526e13d0b74d98c13/core/src/main/resources/org/verapdf/pdfa/validation/PDFUA-1.xml"

# Read XML
xml_doc <- read_xml(url)

# Extract all rule nodes
rules <- xml_find_all(
  xml_doc,
  ".//d1:rule",
  ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
)

# Parse each rule into a tibble
vera_explanations <- tibble(
  # Extract attributes
  object = xml_attr(rules, "object"),
  tags = xml_attr(rules, "tags"),

  # Extract child elements
  specification = map_chr(
    rules,
    ~ xml_text(xml_find_first(
      .x,
      ".//d1:id/@specification",
      ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
    ))
  ),
  clause = map_chr(
    rules,
    ~ xml_text(xml_find_first(
      .x,
      ".//d1:id/@clause",
      ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
    ))
  ),
  test_number = map_chr(
    rules,
    ~ xml_text(xml_find_first(
      .x,
      ".//d1:id/@testNumber",
      ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
    ))
  ),

  description = map_chr(
    rules,
    ~ xml_text(xml_find_first(
      .x,
      ".//d1:description",
      ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
    ))
  ),
  test = map_chr(
    rules,
    ~ xml_text(xml_find_first(
      .x,
      ".//d1:test",
      ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
    ))
  ),
  message = map_chr(
    rules,
    ~ xml_text(xml_find_first(
      .x,
      ".//d1:error/d1:message",
      ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
    ))
  ),

  # Extract arguments (may be multiple)
  arguments = map(
    rules,
    ~ {
      args <- xml_find_all(
        .x,
        ".//d1:error/d1:arguments/d1:argument",
        ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
      )
      if (length(args) > 0) {
        xml_text(args)
      } else {
        NA_character_
      }
    }
  ),

  # Extract references (may be multiple)
  references = map(
    rules,
    ~ {
      refs <- xml_find_all(
        .x,
        ".//d1:references/d1:reference",
        ns = c(d1 = "http://www.verapdf.org/ValidationProfile")
      )
      if (length(refs) > 0) {
        tibble(
          ref_specification = xml_attr(refs, "specification"),
          ref_clause = xml_attr(refs, "clause")
        )
      } else {
        NA
      }
    }
  )
) %>%
  # Create a rule ID for easier reference
  mutate(
    rule_id = paste0(specification, "-", clause, ".", test_number),
    .before = 1
  ) %>%
  # Convert test_number to numeric
  mutate(test_number = as.numeric(test_number))

# View the result
print(vera_explanations, n = 20)

vera_explanations

# Translate technical messages to user-friendly explanations ----

# Install ellmer if needed
# install.packages("ellmer")

library(ellmer)

# Create a chat object (using Claude as it's good at this type of task)
# Make sure you have ANTHROPIC_API_KEY set in your .Renviron
chat <- chat_claude(
  system_prompt = "You are an expert at translating technical PDF accessibility
  error messages into clear, friendly explanations for non-technical users.
  Your explanations should:
  - Be concise (1-2 sentences)
  - Avoid technical jargon where possible
  - Explain what the issue means and why it matters for accessibility
  - Use plain language that anyone can understand
  - Focus on the user impact, not the technical implementation"
)

# Function to translate a single message with error handling
translate_message <- function(
  tech_message,
  description,
  object_type,
  chat_obj
) {
  prompt <- glue::glue(
    "Technical error message: {tech_message}

    Technical description: {description}

    Object type: {object_type}

    Please provide a clear, user-friendly explanation of what this error means
    and why it matters for PDF accessibility. Return ONLY the translated message,
    nothing else."
  )

  tryCatch(
    {
      # Get response from AI
      response <- chat_obj$chat(prompt)

      # Extract the text
      as.character(response)
    },
    error = function(e) {
      warning("Error translating message: ", tech_message, "\n", e$message)
      return(tech_message) # Return original if translation fails
    }
  )
}

# Add user-friendly explanations
cat(
  "Translating",
  nrow(vera_explanations),
  "messages to user-friendly language...\n"
)
cat("This will take a few minutes...\n\n")

vera_explanations_friendly <- vera_explanations %>%
  rowwise() %>%
  mutate(
    user_friendly_message = {
      # Show progress every 10 rows
      if (cur_group_id() %% 10 == 0) {
        cat(
          "Processing row",
          cur_group_id(),
          "of",
          nrow(vera_explanations),
          "\n"
        )
      }
      translate_message(message, description, object, chat)
    }
  ) %>%
  ungroup()

cat("\nTranslation complete!\n")

vera_explanations_friendly |>
  select(message, user_friendly_message) |>
  view()

# Save for later use
saveRDS(vera_explanations_friendly, "data-raw/vera_explanations.rds")
write_csv(
  vera_explanations_friendly %>% select(-arguments, -references),
  "data-raw/vera_explanations.csv"
)

cat("Files saved to data-raw/\n")
