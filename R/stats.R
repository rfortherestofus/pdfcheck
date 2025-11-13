#' @title Retrieve specific accessibility info
#'
#' @description
#' Utility functions to retrieve specific informations
#' about PDF accessibility.
#'
#' @param x Output from `verapdf()`
#'
#' @examples
#' \dontrun{
#' verapdf("inst/pdf/not-compliant-1.pdf") |>
#'   get_total_failed_checks()
#'
#' verapdf("inst/pdf/not-compliant-1.pdf") |>
#'   get_total_failed_rules()
#'
#' verapdf("inst/pdf/not-compliant-1.pdf") |>
#'   get_verapdf_version()
#' }
#'
#' @name info
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
