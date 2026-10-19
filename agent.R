#' Build the AML demo agent
#'
#' @param con A DuckDB connection containing the `transactions` view.
#' @param client An ellmer chat client.
#' @return A commons agent.
build_agent <- function(
  con,
  client = ellmer::chat_anthropic(model = "claude-opus-5")
) {
  commons::commons(
    client = client,
    data_sources = list(
      aml = commons::data_source(
        con,
        tables = "transactions",
        dictionary = "dictionaries/aml.yaml"
      )
    ),
    semantic_layer = commons::semantic_layer("measures")
  )
}

#' Open the SAML-D dataset
#'
#' @param path Path to `SAML-D.csv`.
#' @return A DuckDB connection containing a normalized `transactions` view.
open_saml_d <- function(path = saml_d_path()) {
  check_data_file(path)

  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE))
  create_transactions_view(con, normalizePath(path, mustWork = TRUE))
  con
}

saml_d_path <- function() {
  Sys.getenv("SAML_D_PATH", unset = file.path("data", "SAML-D.csv"))
}

check_data_file <- function(path, call = rlang::caller_env()) {
  if (!file.exists(path)) {
    cli::cli_abort(
      c(
        "The SAML-D CSV was not found at {.path {path}}.",
        "i" = "Run {.code Rscript download-data.R} or set {.envvar SAML_D_PATH}."
      ),
      call = call
    )
  }
}

create_transactions_view <- function(con, path) {
  path_sql <- DBI::dbQuoteString(con, path)
  sql <- paste0(
    "CREATE VIEW transactions AS ",
    "SELECT ",
    "CAST(\"Time\" AS TIME) AS transaction_time, ",
    "CAST(\"Date\" AS DATE) AS transaction_date, ",
    "CAST(Sender_account AS VARCHAR) AS sender_account, ",
    "CAST(Receiver_account AS VARCHAR) AS receiver_account, ",
    "CAST(Amount AS DOUBLE) AS amount, ",
    "Payment_currency AS payment_currency, ",
    "Received_currency AS received_currency, ",
    "Sender_bank_location AS sender_bank_location, ",
    "Receiver_bank_location AS receiver_bank_location, ",
    "Payment_type AS payment_type, ",
    "CAST(Is_laundering AS BOOLEAN) AS is_laundering, ",
    "Laundering_type AS laundering_type ",
    "FROM read_csv_auto(", path_sql, ", header = true)"
  )
  DBI::dbExecute(con, sql)
  invisible(con)
}

