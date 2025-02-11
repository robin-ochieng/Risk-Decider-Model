# app.R
library(shiny)
library(shinyjs)
library(text2vec)
library(glmnet)
library(xgboost)
library(httr)

# Set OpenAI API Key (Replace with your key)
Sys.setenv(OPENAI_KEY = "sk-your-key-here")

# Sample trained models (In production, replace with properly trained models)
# Risk classification model
risk_classifier <- function(text) {
  tokens <- tolower(text) %>% word_tokenizer()
  it <- itoken(tokens)
  vocab <- create_vocabulary(it)
  vectorizer <- vocab_vectorizer(vocab)
  dtm <- create_dtm(it, vectorizer)
  
  # Sample coefficients (replace with actual trained model)
  coefs <- matrix(rnorm(ncol(dtm)*3, ncol = 1)
                  prediction <- as.numeric(dtm %*% coefs)
                  ifelse(prediction > 0.5, "High Risk Category", "Standard Risk Category")
}

# Financial impact model
impact_model <- function(frequency, severity) {
  case_when(
    frequency == "frequent" & severity == "high" ~ "significant",
    frequency == "frequent" & severity == "low" ~ "manageable",
    frequency == "rare" & severity == "high" ~ "significant",
    TRUE ~ "manageable"
  )
}

# XGBoost decision model (pretrained example)
train_decision_model <- function() {
  set.seed(42)
  data <- data.frame(
    frequency = factor(sample(c("rare", "frequent"), 100, replace = TRUE)),
    severity = factor(sample(c("low", "high"), 100, replace = TRUE)),
    impact = factor(sample(c("manageable", "significant"), 100, replace = TRUE)),
    mitigation = factor(sample(c("no", "yes"), 100, replace = TRUE)),
    decision = factor(sample(c("insure", "retain"), 100, replace = TRUE)
    )
    
    recipe <- recipe(decision ~ ., data = data) %>%
      step_dummy(all_nominal(), -all_outcomes())
    
    model <- boost_tree() %>%
      set_engine("xgboost") %>%
      set_mode("classification")
    
    workflow() %>%
      add_recipe(recipe) %>%
      add_model(model) %>%
      fit(data)
}

decision_model <- train_decision_model()

# UI
ui <- fluidPage(
  useShinyjs(),
  titlePanel("AI-Powered Risk Decider"),
  tags$head(
    tags$style(HTML("
      .decision-box {
        padding: 20px;
        margin: 10px;
        border-radius: 5px;
        text-align: center;
        font-weight: bold;
      }
      .question {
        background-color: #f8f9fa;
        padding: 15px;
        margin: 10px 0;
        border-left: 4px solid #007bff;
        border-radius: 4px;
      }
      .ai-badge {
        font-size: 0.8em;
        background-color: #e9ecef;
        padding: 2px 8px;
        border-radius: 12px;
        margin-left: 10px;
      }
    "))
  ),
  
  div(id = "main",
      div(class = "question",
          h4("Step 1: Risk Identification", icon("magnifying-glass")),
          textInput("risk", "Describe the potential risk/liability:", 
                    placeholder = "e.g., 'Cybersecurity breach in cloud infrastructure'"),
          div(id = "risk_type", class = "ai-badge")
      )
  ),
  
  conditionalPanel("input.risk !== ''",
                   div(class = "question",
                       h4("Step 2: Risk Frequency", icon("wave-square")),
                       radioButtons("frequency", "How frequent is this risk?",
                                    c("Frequent" = "frequent",
                                      "Rare" = "rare"))
                   )),
  
  conditionalPanel("input.frequency === 'frequent'",
                   div(class = "question",
                       h4("Step 3: Severity Evaluation", icon("weight-scale")),
                       radioButtons("severity", "Severity level:",
                                    c("High Severity" = "high",
                                      "Low Severity" = "low"))
                   )),
  
  conditionalPanel("input.frequency === 'rare'",
                   div(class = "question",
                       h4("Step 3: Financial Impact", icon("coins")),
                       radioButtons("impact_rare", "Financial impact:",
                                    c("Significant Impact" = "significant",
                                      "Manageable Impact" = "manageable"))
                   )),
  
  conditionalPanel("input.severity === 'high'",
                   div(class = "question",
                       h4("Step 4: AI-Predicted Impact", icon("coins"),
                          span(icon("robot"), class = "ai-badge"),
                          radioButtons("impact_frequent", "Financial impact:",
                                       c("Significant Impact" = "significant",
                                         "Manageable Impact" = "manageable"))
                       )),
                   
                   conditionalPanel("input.severity === 'low' || input.impact_rare === 'manageable'",
                                    div(class = "question",
                                        h4("Step 5: Mitigation Strategies", icon("toolbox")),
                                        selectInput("mitigation", "Available mitigation strategies:",
                                                    c("Multiple effective options" = "yes",
                                                      "Limited options" = "no")),
                                        actionLink("ai_mitigation", "Get AI Suggestions", 
                                                   icon = icon("wand-magic-sparkles"))
                                    )),
                   
                   conditionalPanel("input.mitigation !== ''",
                                    div(class = "question",
                                        h4("AI-Driven Decision", icon("brain")),
                                        actionButton("calculate", "Generate Recommendation", 
                                                     class = "btn-primary"),
                                        br(),br(),
                                        uiOutput("decision")
                                    )),
                   
                   actionButton("reset", "Reset Form", icon("arrows-rotate"))
  )
  
  # Server
  server <- function(input, output, session) {
    observeEvent(input$risk, {
      if(nchar(input$risk) > 10) {
        risk_type <- risk_classifier(input$risk)
        shinyjs::html("risk_type", paste(icon("robot"), risk_type))
      }
    })
    
    observe({
      if(input$frequency == "frequent" && !is.null(input$severity)) {
        predicted_impact <- impact_model(input$frequency, input$severity)
        updateRadioButtons(session, "impact_frequent", selected = predicted_impact)
      }
    })
    
    observeEvent(input$ai_mitigation, {
      tryCatch({
        strategies <- POST(
          "https://api.openai.com/v1/chat/completions",
          add_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_KEY"))),
          body = list(
            model = "gpt-3.5-turbo",
            messages = list(
              list(role = "user", 
                   content = paste("Suggest 3 professional mitigation strategies for:", 
                                   input$risk))
            ),
            encode = "json"
          )
          
          content <- content(strategies)$choices[[1]]$message$content
          showModal(modalDialog(
            title = h4(icon("lightbulb"), "AI-Suggested Mitigations"),
            markdown(content),
            footer = modalButton("Close"),
            easyClose = TRUE
          ))
      }, error = function(e) {
        showNotification("Error connecting to AI service", type = "error")
      })
    })
      
      observeEvent(input$calculate, {
        features <- data.frame(
          frequency = factor(input$frequency, levels = c("rare", "frequent")),
          severity = factor(input$severity, levels = c("low", "high")),
          impact = factor(ifelse(input$frequency == "frequent", 
                                 input$impact_frequent, 
                                 input$impact_rare),
                          levels = c("manageable", "significant")),
          mitigation = factor(input$mitigation, levels = c("no", "yes"))
        )
        
        prediction <- predict(decision_model, new_data = features, type = "prob")
        decision <- ifelse(prediction$.pred_insure > 0.6, "insure", "retain")
        
        color <- ifelse(decision == "insure", "#ffcccc", "#ccffcc")
        icon <- ifelse(decision == "insure", 
                       "triangle-exclamation", 
                       "circle-check")
        
        output$decision <- renderUI({
          div(class = "decision-box", style = paste0("background-color:", color),
              h3(toupper(decision), icon(icon)),
              if(decision == "insure") {
                tagList(
                  p("AI Recommendation: Risk transfer recommended"),
                  p(icon("chart-line"), "Model Confidence:", 
                    round(max(prediction)*100, 1), "%")
                )
              } else {
                tagList(
                  p("AI Recommendation: Risk retention advised"),
                  p(icon("chart-line"), "Model Confidence:", 
                    round(max(prediction)*100, 1), "%")
                )
              }
          )
        })
      })
      
      observeEvent(input$reset, {
        reset("main")
        output$decision <- renderUI({})
        shinyjs::html("risk_type", "")
      })
  }
  
  shinyApp(ui, server)