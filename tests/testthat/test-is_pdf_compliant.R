test_that("is PDF/A compliant", {
  pdf <- system.file(
    "pdf",
    "not-compliant-1.pdf",
    package = "pdfcheck",
    mustWork = TRUE
  )
  expect_false(is_pdf_compliant(pdf))

  pdf <- system.file(
    "pdf",
    "not-compliant-2.pdf",
    package = "pdfcheck",
    mustWork = TRUE
  )
  expect_false(is_pdf_compliant(pdf))

  pdf <- system.file(
    "pdf",
    "compliant-1.pdf",
    package = "pdfcheck",
    mustWork = TRUE
  )
  expect_true(is_pdf_compliant(pdf))
})
