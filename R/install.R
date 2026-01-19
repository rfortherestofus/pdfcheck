#' @title Install verapdf CLI
#'
#' @description
#' Simple utility function to install verapdf.
#'
#' @export
install_verapdf <- function() {
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

  install_path <- if (is_unix()) {
    file.path(Sys.getenv("HOME"), "verapdf")
  } else {
    file.path(Sys.getenv("USERPROFILE"), "verapdf", fsep = "\\")
  }
  print(paste0("Installing verapdf at: ", install_path))
  cat("\n\n")

  if (!is_unix()) {
    install_path <- file.path(Sys.getenv("USERPROFILE"), "verapdf")
    dir.create(install_path, recursive = TRUE, showWarnings = FALSE)
  }

  tmp_config <- tempfile(fileext = ".xml")
  xml_content <- readLines(config_installation)
  xml_content <- gsub(
    "<installpath>.*</installpath>",
    glue::glue("<installpath>{install_path}</installpath>"),
    xml_content
  )
  writeLines(xml_content, tmp_config)

  cat(verapdf_installer, " ", tmp_config)
  system2(command = verapdf_installer, args = c(tmp_config))

  # Add the install folder to PATH so R can find verapdf
  if (is_unix()) {
    Sys.setenv(PATH = paste(install_path, Sys.getenv("PATH"), sep = ":"))
  } else {
    # Persistently add install_path to Windows PATH
    install_path <- normalizePath(
      install_path,
      winslash = "\\",
      mustWork = TRUE
    )

    # Add permanently for current user
    system2("setx", args = c("PATH", paste0("\"%PATH%;", install_path, "\"")))

    # Also update R session PATH
    Sys.setenv(PATH = paste(install_path, Sys.getenv("PATH"), sep = ";"))
  }

  message("verapdf installed and PATH updated.")
  cli_name <- if (is_unix()) "verapdf" else "verapdf.bat"
  print(Sys.which(cli_name))
}


#' @keywords internal
is_unix <- function() {
  unix_like <- c("Darwin", "Linux")
  os <- Sys.info()["sysname"]
  if (os %in% unix_like) {
    return(TRUE)
  } else if (os == "Windows") {
    return(FALSE)
  } else {
    stop(
      "pdfcheck only works with MacOS, Windows, and Linux at the moment, not: ",
      os
    )
  }
}
