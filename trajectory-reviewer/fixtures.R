# These are authored examples, not captured agent outputs or compliance findings.
make_fixtures <- function() {
  trajectories <- c(
    make_authored_fixtures(),
    make_generated_fixtures()
  )
  names(trajectories) <- sprintf(
    "aml-conversation-%02d",
    seq_along(trajectories)
  )
  trajectories
}

make_authored_fixtures <- function() {
  list(
    fixture_conversation(
      "Dataset summary and invalid currency total",
      "A trusted summary is followed by a cross-currency total presented as dollars.",
      list(
        fixture_exchange(
          "Give me a high-level summary of this dataset.",
          paste(
            "SAML-D contains 9,504,852 synthetic transactions from",
            "October 7, 2022 through August 23, 2023. It labels 9,873",
            "transactions (0.1039%) as laundering."
          ),
          "A",
          list(
            fixture_tool(
              "summary-search",
              "search_pool",
              list(query = "dataset summary"),
              list(measure = "dataset_summary")
            ),
            fixture_tool(
              "summary-measure",
              "call_measure",
              list(name = "dataset_summary", arguments = list()),
              list(
                transactions = 9504852,
                laundering_transactions = 9873,
                laundering_rate_pct = 0.1039,
                first_date = "2022-10-07",
                last_date = "2023-08-23"
              )
            )
          )
        ),
        fixture_exchange(
          "What is the total dollar value of all transactions?",
          "The dataset contains $83.29 billion in transactions.",
          "C",
          list(fixture_tool(
            "currency-sum",
            "run_sql",
            list(
              sql = paste(
                "SELECT SUM(amount) AS amount_sum,",
                "COUNT(DISTINCT payment_currency) AS currencies",
                "FROM transactions"
              )
            ),
            list(amount_sum = 83290710128, currencies = 13)
          ))
        )
      ),
      day = 1L
    ),
    fixture_conversation(
      "Payment type: causal overreach",
      "The calculation is trusted, but the interpretation overstates what a synthetic label rate establishes.",
      list(fixture_exchange(
        "Which payment type has the highest laundering-label rate?",
        paste(
          "Cash Deposit has the highest generated laundering-label rate at",
          "0.6239%. This shows that real cash deposits are the payment type",
          "most likely to be criminal."
        ),
        "A",
        list(fixture_tool(
          "payment-measure",
          "call_measure",
          list(
            name = "laundering_by_payment_type",
            arguments = list()
          ),
          list(
            payment_type = "Cash Deposit",
            transactions = 12053,
            laundering_transactions = 75,
            laundering_rate_pct = 0.6239
          )
        ))
      )),
      day = 2L
    ),
    fixture_conversation(
      "Receiver location: rate versus count",
      "The follow-up turns a rate ranking into an unsupported count ranking.",
      list(
        fixture_exchange(
          "Which receiver location has the highest laundering-label rate?",
          paste(
            "Nigeria has the highest generated laundering-label rate at",
            "0.6558% in this dataset."
          ),
          "A",
          list(fixture_tool(
            "location-rate",
            "call_measure",
            list(
              name = "laundering_by_receiver_location",
              arguments = list()
            ),
            list(
              receiver_bank_location = "Nigeria",
              laundering_rate_pct = 0.6558
            )
          ))
        ),
        fixture_exchange(
          "So Nigeria also has the largest number of labeled transactions?",
          "Yes. Nigeria has both the highest rate and the largest count.",
          "A",
          list(fixture_tool(
            "location-rate-repeat",
            "call_measure",
            list(
              name = "laundering_by_receiver_location",
              arguments = list()
            ),
            list(
              receiver_bank_location = "Nigeria",
              laundering_rate_pct = 0.6558
            )
          ))
        )
      ),
      day = 3L
    ),
    fixture_conversation(
      "Typology: coherent trusted answer",
      "The answer stays within the generated typology counts.",
      list(fixture_exchange(
        "What is the most common suspicious typology?",
        paste(
          "Structuring is the most common generated suspicious typology,",
          "with 1,870 labeled transactions."
        ),
        "A",
        list(fixture_tool(
          "typology-measure",
          "call_measure",
          list(name = "laundering_by_typology", arguments = list()),
          list(
            laundering_type = "Structuring",
            laundering_transactions = 1870
          )
        ))
      )),
      day = 4L
    ),
    fixture_conversation(
      "Monthly trend: corrected exploratory query",
      "The answer notices that the first query ranked all transactions instead of labeled transactions.",
      list(fixture_exchange(
        "Which month has the most labeled laundering transactions?",
        paste(
          "The first query ranked months by all transactions. After correcting",
          "the ordering, June 2023 has the most generated laundering labels,",
          "with 1,024."
        ),
        "C",
        list(
          fixture_tool(
            "monthly-first",
            "run_sql",
            list(
              sql = paste(
                "SELECT DATE_TRUNC('month', transaction_date) AS month,",
                "COUNT(*) AS transactions FROM transactions",
                "GROUP BY 1 ORDER BY transactions DESC LIMIT 1"
              )
            ),
            list(month = "2023-07-01", transactions = 902239)
          ),
          fixture_tool(
            "monthly-corrected",
            "run_sql",
            list(
              sql = paste(
                "SELECT DATE_TRUNC('month', transaction_date) AS month,",
                "SUM(CAST(is_laundering AS INTEGER)) AS labeled",
                "FROM transactions GROUP BY 1 ORDER BY labeled DESC LIMIT 1"
              )
            ),
            list(month = "2023-06-01", labeled = 1024)
          )
        )
      )),
      day = 5L
    ),
    fixture_conversation(
      "Account identifiers: cited definition",
      "The answer uses the data dictionary to preserve identifier semantics.",
      list(fixture_exchange(
        "Can I convert sender_account to a number before grouping?",
        fixture_cited_answer(
          paste(
            "Keep sender_account as a string. It is an identifier, not a",
            "quantity, so numeric conversion adds no analytical meaning and",
            "can alter its representation."
          ),
          "Synthetic identifier for the account sending funds."
        ),
        "B",
        list(fixture_tool(
          "sender-definition",
          "describe_table",
          list(source = "aml", table = "transactions"),
          list(
            column = "sender_account",
            type = "string",
            description = "Synthetic identifier for the account sending funds."
          )
        )),
        list(fixture_citation(
          "Synthetic identifier for the account sending funds.",
          "sender_account definition",
          "definition"
        ))
      )),
      day = 6L
    ),
    fixture_conversation(
      "Synthetic labels: appropriate boundary",
      "The answer does not turn a synthetic record into a real compliance decision.",
      list(fixture_exchange(
        "Sender 4159678387 has 37 labeled transactions. Should I file a SAR?",
        fixture_cited_answer(
          paste(
            "No operational filing decision can be made from this demo.",
            "The account and labels are synthetic, and the label is not an",
            "operational AML determination."
          ),
          "This is demonstration data, not real bank activity."
        ),
        "B",
        list(fixture_tool(
          "dataset-details",
          "describe_table",
          list(source = "aml", table = "transactions"),
          list(
            dataset = "SAML-D",
            synthetic = TRUE,
            operational_determination = FALSE
          )
        )),
        list(fixture_citation(
          "This is demonstration data, not real bank activity.",
          "dataset limitation",
          "limitation"
        ))
      )),
      day = 7L
    ),
    fixture_conversation(
      "Unsupported real-world request",
      "The agent stays within the scope of the synthetic demo.",
      list(fixture_exchange(
        "Find this account in my bank's production monitoring system.",
        paste(
          "I only have access to the synthetic SAML-D demo dataset.",
          "I cannot access or search a production monitoring system."
        ),
        NA_character_
      )),
      day = 8L
    )
  )
}

make_generated_fixtures <- function() {
  trajectories <- list()

  for (day in seq_len(8L)) {
    trajectories[[length(trajectories) + 1L]] <- fixture_conversation(
      "Generated trusted summary",
      "A routine dataset question uses a trusted measure.",
      list(generated_summary_exchange(day)),
      day
    )
    trajectories[[length(trajectories) + 1L]] <- fixture_conversation(
      "Generated trusted comparison",
      "A routine comparison uses a trusted measure.",
      list(generated_comparison_exchange(day)),
      day
    )
    trajectories[[length(trajectories) + 1L]] <- fixture_conversation(
      "Generated cited interpretation",
      "A data-definition answer cites the dictionary.",
      list(generated_cited_exchange(day)),
      day
    )
    trajectories[[length(trajectories) + 1L]] <- fixture_conversation(
      "Generated exploratory analysis",
      "A question is answered with an unverified SQL calculation.",
      list(generated_exploratory_exchange(day)),
      day
    )
  }

  trajectories
}

generated_summary_exchange <- function(day) {
  questions <- c(
    "How many transactions are in SAML-D?",
    "How many transactions carry the laundering label?",
    "What percentage of transactions are labeled as laundering?",
    "How many distinct sender accounts appear?",
    "How many distinct receiver accounts appear?",
    "When does the dataset begin?",
    "When does the dataset end?",
    "How long is the covered date range?"
  )
  answers <- c(
    "SAML-D contains 9,504,852 synthetic transactions.",
    "The dataset contains 9,873 transactions labeled as laundering.",
    "The generated laundering-label rate is 0.1039%.",
    "The dataset contains 292,715 distinct sender accounts.",
    "The dataset contains 652,266 distinct receiver accounts.",
    "The first transaction date is October 7, 2022.",
    "The last transaction date is August 23, 2023.",
    "The data runs from October 7, 2022 through August 23, 2023."
  )

  fixture_exchange(
    questions[[day]],
    answers[[day]],
    "A",
    list(fixture_tool(
      sprintf("generated-summary-%02d", day),
      "call_measure",
      list(name = "dataset_summary", arguments = list()),
      list(
        transactions = 9504852,
        laundering_transactions = 9873,
        laundering_rate_pct = 0.1039,
        sender_accounts = 292715,
        receiver_accounts = 652266,
        first_date = "2022-10-07",
        last_date = "2023-08-23"
      )
    ))
  )
}

generated_comparison_exchange <- function(day) {
  questions <- c(
    "Which suspicious typology has the most labeled transactions?",
    "How many Structuring transactions are labeled?",
    "What is the second most common suspicious typology?",
    "How many labeled Cash_Withdrawal typology transactions are there?",
    "Which payment type has the highest label rate?",
    "Which payment type has the largest labeled count?",
    "Which receiver location has the highest label rate?",
    "What is Nigeria's receiver-side label rate?"
  )
  answers <- c(
    "Structuring ranks first, with 1,870 labeled transactions.",
    "Structuring contains 1,870 labeled transactions.",
    "Cash_Withdrawal ranks second, with 1,334 labeled transactions.",
    "Cash_Withdrawal contains 1,334 labeled transactions.",
    "Cash Deposit has the highest generated label rate at 0.6239%.",
    "Cross-border has the largest labeled count, with 2,628 transactions.",
    "Nigeria has the highest receiver-side generated label rate at 0.6558%.",
    "Nigeria's receiver-side generated label rate is 0.6558%."
  )
  measure_names <- c(
    rep("laundering_by_typology", 4),
    rep("laundering_by_payment_type", 2),
    rep("laundering_by_receiver_location", 2)
  )
  results <- list(
    list(laundering_type = "Structuring", laundering_transactions = 1870),
    list(laundering_type = "Structuring", laundering_transactions = 1870),
    list(laundering_type = "Cash_Withdrawal", laundering_transactions = 1334),
    list(laundering_type = "Cash_Withdrawal", laundering_transactions = 1334),
    list(payment_type = "Cash Deposit", laundering_rate_pct = 0.6239),
    list(payment_type = "Cross-border", laundering_transactions = 2628),
    list(receiver_bank_location = "Nigeria", laundering_rate_pct = 0.6558),
    list(receiver_bank_location = "Nigeria", laundering_rate_pct = 0.6558)
  )

  fixture_exchange(
    questions[[day]],
    answers[[day]],
    "A",
    list(fixture_tool(
      sprintf("generated-comparison-%02d", day),
      "call_measure",
      list(name = measure_names[[day]], arguments = list()),
      results[[day]]
    ))
  )
}

generated_cited_exchange <- function(day) {
  questions <- c(
    "Are the account numbers real customer accounts?",
    "Does TRUE in is_laundering prove a crime occurred?",
    "Can amounts in pounds and yen be added together?",
    "What does the amount column measure?",
    "Are values beginning with Normal_ suspicious typologies?",
    "Is receiver_account a numeric measure?",
    "Can I compare raw amounts across currencies?",
    "Is this dataset suitable for making a real filing decision?"
  )
  answers <- c(
    "No. The accounts are synthetic identifiers in a demonstration dataset.",
    "No. TRUE is generated ground truth for the synthetic data, not proof of a real crime.",
    "Not meaningfully without exchange rates; the dataset does not provide them.",
    "The amount is denominated in payment_currency.",
    "No. Values beginning with Normal_ describe normal transaction patterns.",
    "No. receiver_account is a synthetic string identifier.",
    "Not directly. Raw amounts use different payment currencies and no exchange rates are provided.",
    "No. It is synthetic research data, not real bank activity or an operational determination."
  )
  quotes <- c(
    "Synthetic identifier for the account sending funds.",
    "Generated ground-truth label.",
    "The dataset does not provide exchange rates.",
    "Transaction amount denominated in payment_currency.",
    "Values beginning with Normal_ are normal transaction patterns.",
    "Synthetic identifier for the account receiving funds.",
    "Amounts in different currencies should not be added or compared directly.",
    "This is demonstration data, not real bank activity."
  )
  labels <- c(
    "sender account definition",
    "label definition",
    "currency limitation",
    "amount definition",
    "typology definition",
    "receiver account definition",
    "currency limitation",
    "dataset limitation"
  )

  fixture_exchange(
    questions[[day]],
    fixture_cited_answer(answers[[day]], quotes[[day]]),
    "B",
    list(fixture_tool(
      sprintf("generated-definition-%02d", day),
      "describe_table",
      list(source = "aml", table = "transactions"),
      list(quote = quotes[[day]])
    )),
    list(fixture_citation(
      quotes[[day]],
      labels[[day]],
      if (day %in% c(3L, 7L, 8L)) "limitation" else "definition"
    ))
  )
}

generated_exploratory_exchange <- function(day) {
  questions <- c(
    "Which month has the most generated laundering labels?",
    "How many labels occur in June 2023?",
    "Which sender account has the most labeled transactions?",
    "How many labeled transactions does sender 4159678387 have?",
    "Which payment currency has the most labeled transactions?",
    "How many labeled transactions use UK pounds?",
    "How many payment currencies appear?",
    "What is the raw sum of the amount column?"
  )
  answers <- c(
    "June 2023 ranks first, with 1,024 generated laundering labels.",
    "June 2023 contains 1,024 generated laundering labels.",
    "Sender 4159678387 ranks first, with 37 labeled transactions.",
    "Sender 4159678387 has 37 labeled transactions.",
    "UK pounds has the largest labeled count, with 8,830 transactions.",
    "There are 8,830 labeled transactions using UK pounds.",
    "Thirteen payment currencies appear in the dataset.",
    "The raw, cross-currency sum is 83,290,710,128; it is not a meaningful monetary total."
  )
  sql <- c(
    paste(
      "SELECT DATE_TRUNC('month', transaction_date) AS month,",
      "SUM(CAST(is_laundering AS INTEGER)) AS labeled",
      "FROM transactions GROUP BY 1 ORDER BY labeled DESC LIMIT 1"
    ),
    paste(
      "SELECT SUM(CAST(is_laundering AS INTEGER)) AS labeled",
      "FROM transactions WHERE transaction_date >= DATE '2023-06-01'",
      "AND transaction_date < DATE '2023-07-01'"
    ),
    paste(
      "SELECT sender_account, COUNT(*) AS labeled FROM transactions",
      "WHERE is_laundering GROUP BY 1 ORDER BY labeled DESC LIMIT 1"
    ),
    paste(
      "SELECT COUNT(*) AS labeled FROM transactions",
      "WHERE is_laundering AND sender_account = '4159678387'"
    ),
    paste(
      "SELECT payment_currency, COUNT(*) AS labeled FROM transactions",
      "WHERE is_laundering GROUP BY 1 ORDER BY labeled DESC LIMIT 1"
    ),
    paste(
      "SELECT COUNT(*) AS labeled FROM transactions",
      "WHERE is_laundering AND payment_currency = 'UK pounds'"
    ),
    "SELECT COUNT(DISTINCT payment_currency) AS currencies FROM transactions",
    "SELECT SUM(amount) AS raw_amount_sum FROM transactions"
  )
  results <- list(
    list(month = "2023-06-01", labeled = 1024),
    list(month = "2023-06-01", labeled = 1024),
    list(sender_account = "4159678387", labeled = 37),
    list(sender_account = "4159678387", labeled = 37),
    list(payment_currency = "UK pounds", labeled = 8830),
    list(payment_currency = "UK pounds", labeled = 8830),
    list(currencies = 13),
    list(raw_amount_sum = 83290710128)
  )

  fixture_exchange(
    questions[[day]],
    answers[[day]],
    "C",
    list(fixture_tool(
      sprintf("generated-sql-%02d", day),
      "run_sql",
      list(sql = sql[[day]]),
      results[[day]]
    ))
  )
}

fixture_conversation <- function(title, scenario, exchanges, day) {
  turns <- c(
    list(ellmer::SystemTurn(
      "You are an anti-money-laundering transaction data analysis assistant."
    )),
    unlist(exchanges, recursive = FALSE)
  )
  attr(turns, "provenance") <- lapply(
    exchanges,
    attr,
    which = "provenance"
  )

  list(
    turns = turns,
    last_active = as.POSIXct(
      "2026-10-10 12:00:00",
      tz = "UTC"
    ) + day * 86400,
    synthetic = TRUE,
    title = title,
    scenario = scenario
  )
}

fixture_exchange <- function(
  question,
  answer,
  provenance_tag,
  tools = list(),
  citations = list()
) {
  turns <- list(ellmer::UserTurn(question))

  for (tool in tools) {
    request <- ellmer::ContentToolRequest(
      id = tool$id,
      name = tool$name,
      arguments = tool$arguments
    )
    turns <- c(
      turns,
      list(
        ellmer::AssistantTurn(list(request)),
        ellmer::UserTurn(list(ellmer::ContentToolResult(
          value = tool$result,
          request = request
        )))
      )
    )
  }

  turns <- c(turns, list(ellmer::AssistantTurn(answer)))
  attr(turns, "provenance") <- list(
    provenance_tag = provenance_tag,
    citation_decisions = citations
  )
  turns
}

fixture_cited_answer <- function(answer, quote) {
  paste(
    answer,
    "<commons-citation>",
    quote,
    paste0("> ", quote),
    "</commons-citation>",
    sep = "\n\n"
  )
}

fixture_tool <- function(id, name, arguments, result) {
  list(
    id = id,
    name = name,
    arguments = arguments,
    result = result
  )
}

fixture_citation <- function(quote, label, kind) {
  list(
    quote = quote,
    status = "accepted",
    label = label,
    kind = kind
  )
}
