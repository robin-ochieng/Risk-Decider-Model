library(shiny)
library(shinyjs)

ui <- fluidPage(
  useShinyjs(),
  titlePanel("Professional Risk Decision Tree"),
  tags$style(HTML("
    .decision-box {
      padding: 20px;
      margin: 10px;
      border-radius: 5px;
      text-align: center;
      font-weight: bold;
    }
    .question {
      background-color: #e6f3ff;
      padding: 15px;
      margin: 10px 0;
      border-left: 5px solid #007bff;
    }
  ")),
  
  div(id = "main",
      div(class = "question",
          h4("Step 1: Identify the Risk", icon("magnifying-glass")),
          textInput("risk", "Describe the potential risk/liability:", 
                    placeholder = "Enter risk description...")
      )
  ),
  
  conditionalPanel("input.risk !== ''",
                   div(class = "question",
                       h4("Step 2: Assess Frequency", icon("wave-square")),
                       radioButtons("frequency", "How frequent is this risk?",
                                    c("Frequent" = "frequent",
                                      "Rare" = "rare"))
                   )),
  
  conditionalPanel("input.frequency === 'frequent'",
                   div(class = "question",
                       h4("Step 3: Evaluate Severity", icon("weight-scale")),
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
                       h4("Step 4: Financial Impact", icon("coins")),
                       radioButtons("impact_frequent", "Financial impact:",
                                    c("Significant Impact" = "significant",
                                      "Manageable Impact" = "manageable"))
                   )),
  
  conditionalPanel("input.severity === 'low' || input.impact_rare === 'manageable'",
                   div(class = "question",
                       h4("Step 5: Risk Mitigation", icon("toolbox")),
                       selectInput("mitigation", "Available mitigation strategies:",
                                   c("Multiple effective options" = "yes",
                                     "Limited options" = "no"))
                   )),
  
  conditionalPanel("input.mitigation !== ''",
                   div(class = "question",
                       h4("Final Decision", icon("flag-checkered")),
                       actionButton("calculate", "Determine Recommendation", 
                                    class = "btn-primary"),
                       br(),br(),
                       uiOutput("decision")
                   )),
  
  actionButton("reset", "Reset Form", icon("arrows-rotate"))
)

server <- function(input, output, session) {
  observeEvent(input$reset, {
    reset("main")
    output$decision <- renderUI({})
  })
  
  observeEvent(input$calculate, {
    decision <- if (input$frequency == "frequent") {
      if (input$severity == "high" && input$impact_frequent == "significant") "insure"
      else if (input$mitigation == "yes") "retain"
      else "insure"
    } else {
      if (input$impact_rare == "significant") "insure"
      else if (input$mitigation == "yes") "retain"
      else "retain"
    }
    
    color <- ifelse(decision == "insure", "#ffcccc", "#ccffcc")
    icon <- ifelse(decision == "insure", 
                   "triangle-exclamation", 
                   "circle-check")
    
    output$decision <- renderUI({
      div(class = "decision-box", style = paste0("background-color:", color),
          h3(toupper(decision), icon(icon)),
          if(decision == "insure") {
            p("Recommendation: Transfer risk through insurance due to high severity/frequency and significant financial impact")
          } else {
            p("Recommendation: Retain risk with mitigation strategies as it's financially manageable")
          }
      )
    })
  })
}

shinyApp(ui, server)