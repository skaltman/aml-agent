#' Download the SAML-D dataset
#'
#' @param destination Destination for the extracted CSV.
#' @param overwrite Whether to replace an existing CSV.
#' @return The destination path, invisibly.
download_saml_d <- function(
  destination = file.path("data", "SAML-D.csv"),
  overwrite = FALSE
) {
  if (file.exists(destination) && !overwrite) {
    cli::cli_inform("Using existing dataset at {.path {destination}}.")
    return(invisible(destination))
  }

  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  archive <- tempfile(fileext = ".zip")
  extract_dir <- tempfile()
  on.exit(unlink(c(archive, extract_dir), recursive = TRUE), add = TRUE)

  cli::cli_inform("Downloading SAML-D from Kaggle...")
  utils::download.file(saml_d_download_url(), archive, mode = "wb", quiet = TRUE)
  utils::unzip(archive, files = "SAML-D.csv", exdir = extract_dir)

  extracted <- file.path(extract_dir, "SAML-D.csv")
  if (!file.exists(extracted)) {
    cli::cli_abort("The downloaded archive does not contain {.file SAML-D.csv}.")
  }

  if (!file.rename(extracted, destination)) {
    file.copy(extracted, destination, overwrite = TRUE)
  }

  cli::cli_alert_success("Saved SAML-D to {.path {destination}}.")
  invisible(destination)
}

saml_d_download_url <- function() {
  paste0(
    "https://www.kaggle.com/api/v1/datasets/download/",
    "berkanoztas/synthetic-transaction-monitoring-dataset-aml",
    "?datasetVersionNumber=2"
  )
}

download_saml_d()

