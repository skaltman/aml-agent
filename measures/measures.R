#' Dataset summary
#'
#' @description
#' Counts transactions, generated laundering labels, distinct sender and
#' receiver accounts, and the covered date range.
#'
#' @return A one-row data frame of dataset summary statistics.
#' @provenance https://www.kaggle.com/datasets/berkanoztas/synthetic-transaction-monitoring-dataset-aml/data (retrieved 2026-10-16)
#' @measure
dataset_summary <- function(aml) {
  query_aml(
    aml,
    "
    SELECT
      COUNT(*) AS transactions,
      SUM(CAST(is_laundering AS INTEGER)) AS laundering_transactions,
      ROUND(100 * AVG(CAST(is_laundering AS INTEGER)), 4) AS laundering_rate_pct,
      COUNT(DISTINCT sender_account) AS sender_accounts,
      COUNT(DISTINCT receiver_account) AS receiver_accounts,
      MIN(transaction_date) AS first_date,
      MAX(transaction_date) AS last_date
    FROM transactions
    "
  )
}

#' Laundering transactions by typology
#'
#' @description
#' Counts generated laundering transactions for each suspicious typology.
#'
#' @return A data frame ordered from the most to least common typology.
#' @provenance https://ieeexplore.ieee.org/document/10356193 (retrieved 2026-10-16)
#' @measure
laundering_by_typology <- function(aml) {
  query_aml(
    aml,
    "
    SELECT
      laundering_type,
      COUNT(*) AS laundering_transactions,
      ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
    FROM transactions
    WHERE is_laundering
    GROUP BY laundering_type
    ORDER BY laundering_transactions DESC, laundering_type
    "
  )
}

#' Laundering rate by payment type
#'
#' @description
#' Compares transaction counts and generated laundering-label rates across
#' payment types.
#'
#' @return A data frame ordered from highest to lowest laundering-label rate.
#' @provenance https://github.com/BOztasUK/Anti_Money_Laundering_Transaction_Data_SAML-D/blob/main/saml-d-exploratory-data-analysis-classification%20(1).ipynb
#' @measure
laundering_by_payment_type <- function(aml) {
  query_aml(
    aml,
    "
    SELECT
      payment_type,
      COUNT(*) AS transactions,
      SUM(CAST(is_laundering AS INTEGER)) AS laundering_transactions,
      ROUND(100 * AVG(CAST(is_laundering AS INTEGER)), 4) AS laundering_rate_pct
    FROM transactions
    GROUP BY payment_type
    ORDER BY laundering_rate_pct DESC, payment_type
    "
  )
}

#' Laundering rate by receiver location
#'
#' @description
#' Compares transaction counts and generated laundering-label rates across
#' receiver bank locations.
#'
#' @return A data frame ordered from highest to lowest laundering-label rate.
#' @provenance https://github.com/BOztasUK/Anti_Money_Laundering_Transaction_Data_SAML-D/blob/main/saml-d-exploratory-data-analysis-classification%20(1).ipynb
#' @measure
laundering_by_receiver_location <- function(aml) {
  query_aml(
    aml,
    "
    SELECT
      receiver_bank_location,
      COUNT(*) AS transactions,
      SUM(CAST(is_laundering AS INTEGER)) AS laundering_transactions,
      ROUND(100 * AVG(CAST(is_laundering AS INTEGER)), 4) AS laundering_rate_pct
    FROM transactions
    GROUP BY receiver_bank_location
    ORDER BY laundering_rate_pct DESC, receiver_bank_location
    "
  )
}

query_aml <- function(aml, sql) {
  DBI::dbGetQuery(aml, sql)
}

