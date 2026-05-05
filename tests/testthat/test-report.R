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
