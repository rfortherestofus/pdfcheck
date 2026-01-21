#' @title Install veraPDF CLI
#'
#' @description
#' Robust utility to install veraPDF. Handles Windows path limits and
#' version-specific directory structures.
#'
#' @export
install_verapdf <- function() {
  is_unix <- function() {
    os <- Sys.info()["sysname"]
    return(os %in% c("Darwin", "Linux"))
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
    # Normalize to backslashes for the Windows installer [7]
    normalizePath(
      file.path(Sys.getenv("USERPROFILE"), "verapdf"),
      winslash = "\\",
      mustWork = FALSE
    )
  }

  if (!is_unix() && !dir.exists(install_path)) {
    dir.create(install_path, recursive = TRUE, showWarnings = FALSE)
  }

  message("Installing veraPDF at: ", install_path)

  tmp_config <- tempfile(fileext = ".xml")
  xml_content <- readLines(config_installation)
  # Ensure the XML contains the correctly formatted path [7, 8]
  xml_content <- gsub(
    "<installpath>.*</installpath>",
    glue::glue("<installpath>{install_path}</installpath>"),
    xml_content
  )
  writeLines(xml_content, tmp_config)

  # Execute installer [9, 1]
  system2(command = verapdf_installer, args = shQuote(tmp_config))

  # Post-install: Detect executable location
  # Check root first, then bin
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
  }

  # Update R session PATH
  sep <- if (is_unix()) ":" else ";"
  Sys.setenv(PATH = paste(found_bin, Sys.getenv("PATH"), sep = sep))

  # Update Windows User PATH safely
  # Avoiding %PATH% recursion prevents the 1024-character truncation error
  if (!is_unix()) {
    # Using 'set' without appending the existing path is safer for session
    # but for persistence, it is better to add only the new entry to the Registry
    # or use a simplified setx if you only want to track this specific tool.
    try(
      system2("setx", args = c("VERAPDF_BIN", shQuote(found_bin))),
      silent = TRUE
    )
    message("Persistent variable VERAPDF_BIN created to avoid PATH truncation.")
  }

  message("veraPDF installed successfully.")
  # Sys.which will now find it [3]
  print(Sys.which("verapdf"))
}
