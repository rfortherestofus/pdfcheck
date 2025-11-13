test_that("is PDF/A compliant", {
  pdf <- "inst/pdf/not-compliant-1.pdf"
  expect_false(is_pdf_compliant(pdf))

  pdf <- "inst/pdf/not-compliant-2.pdf"
  expect_false(is_pdf_compliant(pdf))

  pdf <- "inst/pdf/compliant-1.pdf"
  expect_true(is_pdf_compliant(pdf))
})
