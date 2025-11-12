#' @title Does this PDF comply with accessibility standards?
#'
#' @description
#' Check whether a given PDF file is compliant to PDF/UA-1 (default).
#'
#' @param file PDF file to check.
#' @param profile The validation profile to use. Default to `"ua1"` (recommended).
#'
#' @return A logical
#'
#' @export
#'
#' @examples
#' \dontrun{
#' is_pdf_compliant("report.pdf")
#' is_pdf_compliant("report.pdf", profile="ua2")
#' }
is_pdf_compliant <- function(file, profile = "ua1") {
  json <- verapdf(file = file, profile = profile, format = "json")
  is_compliant <- json$report$jobs$validationResult[[1]]$compliant
  return(is_compliant)
}
