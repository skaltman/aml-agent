withr::with_options(
  list(rsconnect.python.enabled = FALSE),
  rsconnect::deployApp(
    appDir = ".",
    account = "posit",
    server = "connect.posit.cloud",
    appFiles = c(
      "app.R",
      "agent.R",
      "DESCRIPTION",
      "dictionaries/aml.yaml",
      "measures/measures.R",
      "data/SAML-D.csv"
    )
  )
)
