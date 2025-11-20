#' @import glue
install_verapdf <- function() {
  script_install <- if (is_unix()) "verapdf-install" else "verapdf-install.bat"

  # Locate installer and config
  verapdf_installer <- system.file(
    "verapdf-greenfield-1.28.2",
    script_install,
    mustWork = TRUE,
    package = "checkpdf"
  )
  config_installation <- system.file(
    "verapdf-greenfield-1.28.2",
    "install-config.xml",
    mustWork = TRUE,
    package = "checkpdf"
  )

  # Determine dynamic install path
  install_path <- if (is_unix()) {
    file.path(Sys.getenv("HOME"), "verapdf")
  } else {
    file.path(Sys.getenv("USERPROFILE"), "verapdf")
  }

  # Update the install path in a temporary XML copy
  tmp_config <- tempfile(fileext = ".xml")
  xml_content <- readLines(config_installation)
  xml_content <- gsub(
    "<installpath>.*</installpath>",
    glue::glue("<installpath>{install_path}</installpath>"),
    xml_content
  )
  writeLines(xml_content, tmp_config)

  # Run installer with modified config
  system2(command = verapdf_installer, args = c(tmp_config))
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
      "checkpdf only works with MacOS, Windows, and Linux at the moment, not: ",
      os
    )
  }
}
