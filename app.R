source("agent.R", local = TRUE)

aml_con <- open_saml_d()

greeting <- paste(
  "Ask questions about the synthetic SAML-D transaction monitoring dataset.",
  "\n\nFor example:\n\n",
  "- <span class='suggestion'>How many transactions are labeled as laundering?</span>\n",
  "- <span class='suggestion'>Which laundering typologies are most common?</span>\n",
  "- <span class='suggestion'>How does the laundering rate vary by payment type?</span>\n"
)

ui <- shinychat::page_chat(
  "AML agent",
  id = "chat",
  greeting = greeting,
  theme = commons::commons_theme()
)

server <- function(input, output, session) {
  agent <- build_agent(aml_con)
  commons::commons_server("chat", agent)
}

shiny::shinyApp(ui, server)

