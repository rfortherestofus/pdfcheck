#' @title Install veraPDF CLI
#'
#' @description
#' Robust utility to install veraPDF. Handles Windows path limits and
#' version-specific directory structures.
#'
#' On Windows, this function persists the installation directory in the
#' VERAPDF_BIN environment variable and updates ~/.Rprofile so future R
#' sessions prepend that directory to PATH.
#'
#' @export
install_verapdf <- function() {
  is_unix <- function() {
    os <- Sys.info()[["sysname"]]
    os %in% c("Darwin", "Linux")
  }

  append_verapdf_to_rprofile <- function(found_bin) {
    rprofile <- path.expand("~/.Rprofile")

    block <- c(
      "",
      "# pdfcheck veraPDF startup hook",
      "local({",
      "  verapdf_bin <- Sys.getenv(\"VERAPDF_BIN\", \"\")",
      "  if (nzchar(verapdf_bin) && dir.exists(verapdf_bin)) {",
      "    sep <- if (.Platform$OS.type == \"windows\") \";\" else \":\"",
      "    current_path <- Sys.getenv(\"PATH\")",
      "    path_entries <- strsplit(current_path, split = sep, fixed = TRUE)[[1]]",
      "    if (!(verapdf_bin %in% path_entries)) {",
      "      Sys.setenv(PATH = paste(verapdf_bin, current_path, sep = sep))",
      "    }",
      "  }",
      "})"
    )

    if (file.exists(rprofile)) {
      existing <- readLines(rprofile, warn = FALSE)
      if (any(grepl("^# pdfcheck veraPDF startup hook$", existing))) {
        return(invisible(FALSE))
      }
      writeLines(c(existing, block), rprofile)
      return(invisible(TRUE))
    }

    writeLines(block, rprofile)
    invisible(TRUE)
  }

  script_install <- if (is_unix()) "verapdf-install" else "verapdf-install.bat"

  verapdf_installer <- system.file(
    "verapdf-greenfield-1.28.2",
    script_install,
    mustWork = TRUE,
    package = "pdfcheck"
  )

  config_installation <- system.file(
    "verapdf-greenfield-1.28.2",
    if (is_unix()) "install-config.xml" else "install-config-windows.xml",
    mustWork = TRUE,
    package = "pdfcheck"
  )

  # Use consistent path separators for Windows [5, 6]
  install_path <- if (is_unix()) {
    file.path(Sys.getenv("HOME"), "verapdf")
  } else {
    normalizePath(
      file.path(Sys.getenv("USERPROFILE"), "verapdf"),
      winslash = "\\",
      mustWork = FALSE
    )
  }

  if (!dir.exists(install_path)) {
    dir.create(install_path, recursive = TRUE, showWarnings = FALSE)
  }

  message("Installing veraPDF at: ", install_path)

  tmp_config <- tempfile(fileext = ".xml")
  on.exit(unlink(tmp_config, force = TRUE), add = TRUE)

  xml_content <- readLines(config_installation, warn = FALSE)
  xml_content <- gsub(
    "<installpath>.*</installpath>",
    glue::glue("<installpath>{install_path}</installpath>"),
    xml_content
  )
  writeLines(xml_content, tmp_config)

  result <- system2(
    command = verapdf_installer,
    args = shQuote(tmp_config),
    stdout = "",
    stderr = ""
  )

  if (!identical(result, 0L)) {
    stop("veraPDF installer failed with exit status: ", result)
  }

  possible_bins <- c(install_path, file.path(install_path, "bin"))
  executable_name <- if (is_unix()) "verapdf" else "verapdf.bat"

  found_bin <- NULL
  for (path in possible_bins) {
    if (file.exists(file.path(path, executable_name))) {
      found_bin <- path
      break
    }
  }

  if (is.null(found_bin)) {
    stop(
      "Installation finished, but verapdf executable was not found in root or bin folder."
    )
    message("Persistent variable VERAPDF_BIN created to avoid PATH truncation.")
  }

  sep <- if (is_unix()) ":" else ";"
  current_path <- Sys.getenv("PATH")
  path_entries <- strsplit(current_path, split = sep, fixed = TRUE)[[1]]
  if (!(found_bin %in% path_entries)) {
    Sys.setenv(PATH = paste(found_bin, current_path, sep = sep))
  }

  if (!is_unix()) {
    try(
      system2("setx", args = c("VERAPDF_BIN", shQuote(found_bin))),
      silent = TRUE
    )
    append_verapdf_to_rprofile(found_bin)
    message("Persistent variable VERAPDF_BIN created.")
    message(
      "Updated ~/.Rprofile so future R sessions prepend VERAPDF_BIN to PATH."
    )
    message(
      "Restart R to make verapdf available automatically via Sys.which()."
    )
  }

  message("veraPDF installed successfully.")
  print(Sys.which("verapdf"))

  invisible(found_bin)
}
