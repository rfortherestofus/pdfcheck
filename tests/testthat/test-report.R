test_that("Generated reports are valid", {
  expect_similar_reports <- function(expected, pdf, threshold = 85) {
    expected_report <- system.file(
      "report",
      expected,
      package = "pdfcheck",
      mustWork = TRUE
    )
    pdf <- system.file("pdf", pdf, package = "pdfcheck", mustWork = TRUE)
    actual_report <- accessibility_report(pdf, open = FALSE)

    lines_equal <- readLines(expected_report) == readLines(actual_report)
    equal <- sum(lines_equal)
    total <- length(lines_equal)
    percent <- (equal / total * 100) |> round(digits = 2)
    expect_true(
      percent > threshold,
      label = glue::glue("{percent}% < {threshold}%")
    ) # x% of the report should be the same
  }

  expect_similar_reports("not-compliant-1.html", "not-compliant-1.pdf")
  expect_similar_reports("not-compliant-2.html", "not-compliant-2.pdf")
  expect_similar_reports("compliant-1.html", "compliant-1.pdf")
})

test_that("Generated reports expose accessible modal and decorative icons", {
  pdf <- system.file(
    "pdf",
    "not-compliant-1.pdf",
    package = "pdfcheck",
    mustWork = TRUE
  )
  actual_report <- accessibility_report(pdf, open = FALSE)
  html <- paste0(readLines(actual_report), collapse = "\n")
  doc <- xml2::read_html(actual_report)

  dialog <- xml2::xml_find_all(doc, ".//*[@role='dialog']")
  expect_length(dialog, 1)
  expect_equal(xml2::xml_attr(dialog, "aria-modal"), "true")
  expect_equal(xml2::xml_attr(dialog, "aria-labelledby"), "modal-title")
  expect_equal(xml2::xml_attr(dialog, "aria-describedby"), "modal-description")
  expect_equal(xml2::xml_attr(dialog, "tabindex"), "-1")

  buttons <- xml2::xml_find_all(
    doc,
    "//button[contains(concat(' ', normalize-space(@class), ' '), ' more-info-btn ')]"
  )
  expect_true(length(buttons) > 0)
  expect_true(all(xml2::xml_attr(buttons, "aria-haspopup") == "dialog"))
  expect_true(all(xml2::xml_attr(buttons, "aria-controls") == "details-modal"))

  icons <- xml2::xml_find_all(doc, "//*[local-name()='svg']")
  expect_true(length(icons) > 0)
  expect_true(all(xml2::xml_attr(icons, "aria-hidden") == "true"))
  expect_true(all(xml2::xml_attr(icons, "focusable") == "false"))

  expect_match(html, "modalDialog.focus();", fixed = TRUE)
  expect_match(html, "modalTrigger.focus();", fixed = TRUE)
  expect_match(html, "trapModalFocus(e);", fixed = TRUE)
})
