test_that("Generated reports are valid", {
  expect_similar_reports <- function(expected, pdf, threshold = 99) {
    expected_report <- paste0("inst/report/", expected)
    pdf <- paste0("inst/pdf/", pdf)
    actual_report <- accessibility_report(pdf, open = FALSE)
    actual_report <- here::here(actual_report)
    expected_report <- here::here(expected_report)

    lines_equal <- readLines(expected_report) == readLines(actual_report)
    equal <- sum(lines_equal)
    total <- length(lines_equal)
    percent <- (equal / total * 100) |> round(digits = 2)
    expect_true(
      percent > threshold,
      label = glue::glue("{percent}% < {threshold}%")
    ) # 99% of the report should be the same
  }

  expect_similar_reports("not-compliant-1.html", "not-compliant-1.pdf")
  expect_similar_reports("not-compliant-2.html", "not-compliant-2.pdf")
  expect_similar_reports("compliant-1.html", "compliant-1.pdf")
})
