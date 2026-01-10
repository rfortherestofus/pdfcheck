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
    "install-config.xml",
    mustWork = TRUE,
    package = "pdfcheck"
  )

  install_path <- if (is_unix()) {
    file.path(Sys.getenv("HOME"), "verapdf")
  } else {
    file.path(Sys.getenv("USERPROFILE"), "verapdf")
  }
  print(paste0("Installing verapdf at: ", install_path))
  cat("\n\n")

  tmp_config <- tempfile(fileext = ".xml")
  xml_content <- readLines(config_installation)
  xml_content <- gsub(
    "<installpath>.*</installpath>",
    glue::glue("<installpath>{install_path}</installpath>"),
    xml_content
  )
  writeLines(xml_content, tmp_config)

  system2(command = verapdf_installer, args = c(tmp_config))

  # Add the install folder to PATH so R can find verapdf
  if (is_unix()) {
    Sys.setenv(PATH = paste(install_path, Sys.getenv("PATH"), sep = ":"))
  } else {
    Sys.setenv(PATH = paste(install_path, Sys.getenv("PATH"), sep = ";"))
  }

  message("verapdf installed and PATH updated.")
  print(Sys.which("verapdf"))
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
