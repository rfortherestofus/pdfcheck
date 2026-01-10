#' @title Retrieve specific accessibility info
#'
#' @description
#' Utility functions to retrieve specific informations
#' about PDF accessibility.
#'
#' @param x Output from `verapdf()`
#'
#' @name info
#'
#' @note
#' It is important to understand the difference between
#' rules and checks. A rule that has been failed may
#' be "Missing alternative text on images", and each rule
#' may have several checks that have been failed.
#' For example, if the rule "Missing alt text on images" occurs
#' 10 times in a given PDF, that gives us 10 failed checks
#' for that rule.
#'
#' @examples
#' pdf_file <- system.file("pdf", "not-compliant-1.pdf", package = "pdfcheck")
#'
#' verapdf(pdf_file) |>
#'   get_total_failed_checks()
#'
#' verapdf(pdf_file) |>
#'   get_total_failed_rules()
#'
#' verapdf(pdf_file) |>
#'   get_verapdf_version()
NULL

#' @rdname info
#' @export
get_total_failed_checks <- function(x) {
  x$report$jobs$validationResult[[1]]$details$failedChecks
}

#' @rdname info
#' @export
get_total_failed_rules <- function(x) {
  x$report$jobs$validationResult[[1]]$details$failedRules
}

#' @rdname info
#' @export
get_verapdf_version <- function(x) {
  x$report$buildInformation$releaseDetails$version[[1]]
}
