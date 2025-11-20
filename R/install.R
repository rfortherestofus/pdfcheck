#' @import glue
install_verapdf <- function() {
  script_install <- if (is_unix()) "verapdf-install" else "verapdf-install.bat"
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

  system2(command = verapdf_installer, args = c(config_installation))
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
