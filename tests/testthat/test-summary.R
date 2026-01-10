test_that("is PDF/A compliant", {
  pdf <- system.file(
    "pdf",
    "not-compliant-1.pdf",
    package = "pdfcheck",
    mustWork = TRUE
  )
  output <- capture.output(accessibility_summary(pdf))
  expected <- c(
    "PDF Accessibility Summary",
    "=========================",
    "Verapdf version:  1.28.2 ",
    "Compliant:  No ",
    "Profile:  ua1 ",
    "",
    "Passed Rules:   95 ",
    "Passed Checks:  591 ",
    "Failed Rules:   11 ",
    "Failed Checks:  195 "
  )
  expect_equal(output, expected)

  pdf <- system.file(
    "pdf",
    "compliant-1.pdf",
    package = "pdfcheck",
    mustWork = TRUE
  )
  output <- capture.output(accessibility_summary(pdf))
  expected <- c(
    "PDF Accessibility Summary",
    "=========================",
    "Verapdf version:  1.28.2 ",
    "Compliant:  Yes ",
    "Profile:  ua1 ",
    "",
    "Passed Rules:   106 ",
    "Passed Checks:  17406 ",
    "Failed Rules:   0 ",
    "Failed Checks:  0 "
  )
  expect_equal(output, expected)
})
