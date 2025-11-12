#' @title Call verapdf CLI
#'
#' @description
#' Utility to call verapdf command line interface. It requires
#' the `verapdf` CLI to be on PATH.
#'
#' @param file PDF file to check.
#' @param write_to Path to output file. If `NULL`, does not write.
#' @param format Output format. Default to `"json"`.
#' @param profile The validation profile to use. Default to `"ua1"` (recommended).
#'
#' @returns output from the CLI
#'
#' @export
verapdf <- function(
  file,
  write_to = NULL,
  format = c("json", "xml"),
  profile = c(
    "ua1",
    "ua2",
    "1a",
    "1b",
    "2a",
    "2b",
    "2u",
    "3a",
    "3b",
    "3u",
    "4",
    "4f",
    "4e"
  )
) {
  format <- match.arg(format)
  profile <- match.arg(profile)

  if (!file.exists(file)) {
    stop("File not found: ", file)
  }

  cmd <- system.file("bin", "verapdf", package = "checkpdf")

  if (cmd == "") {
    if (Sys.which("verapdf") == "") {
      stop(
        "`verapdf` CLI not found on PATH. How to install: ",
        "https://docs.verapdf.org/install/"
      )
    } else {
      cmd <- "verapdf"
    }
  }

  cmd <- "verapdf"
  args <- c("--format", format, "--flavour", profile, file)

  out_cli <- suppressWarnings(system2(cmd, args, stdout = TRUE))

  # parse CLI output
  if (format == "json") {
    out <- jsonlite::fromJSON(paste(out_cli, collapse = "\n"))
  } else if (format == "xml") {
    out <- xml2::read_xml(out_cli |> paste0(collapse = " "))
  }

  # optionnaly write to file
  if (!is.null(write_to)) {
    if (format == "json") {
      jsonlite::write_json(out, write_to, auto_unbox = TRUE, pretty = TRUE)
    } else if (format == "xml") {
      xml2::write_xml(out, write_to)
    }
  }

  return(out)
}
