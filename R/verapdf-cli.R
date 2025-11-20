#' @title Call verapdf CLI
#'
#' @description
#' Utility to call verapdf command line interface. It requires
#' the `verapdf` CLI to be on PATH.
#'
#' @param file PDF file to check.
#' @param write_to Path to output file. If `NULL`, does not write.
#' @param profile The validation profile to use. Default to `"ua1"` (recommended).
#'
#' @returns output from the CLI
#'
#' @import here
#'
#' @export
verapdf <- function(
  file,
  write_to = NULL,
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
  profile <- match.arg(profile)

  file <- here::here(file)

  if (!file.exists(file)) {
    stop("File not found: ", file)
  }

  # detect whether we're running inside the CI or not
  ci_flag <- Sys.getenv("INSIDE_CI")

  if (Sys.which("verapdf") == "" && ci_flag == "") {
    stop(
      "`verapdf` CLI not found on PATH. How to install: ",
      "https://docs.verapdf.org/install/"
    )
  }

  cmd <- if (ci_flag == "true") {
    "docker"
  } else {
    "verapdf"
  }

  args <- if (ci_flag == "true") {
    c(
      "run",
      "--rm",
      "-v",
      paste0(dirname(file), ":/data"),
      "verapdf/verapdf",
      "--format",
      "json",
      "--flavour",
      profile,
      paste0("/data/", basename(file))
    )
  } else {
    c("--format", "json", "--flavour", profile, file)
  }

  out_cli <- suppressWarnings(system2(cmd, args, stdout = TRUE))

  # parse CLI output
  out <- jsonlite::fromJSON(paste(out_cli, collapse = "\n"))

  # optionnaly write to file
  if (!is.null(write_to)) {
    jsonlite::write_json(out, write_to, auto_unbox = TRUE, pretty = TRUE)
  }

  out <- structure(out, class = "verapdf")

  return(out)
}
