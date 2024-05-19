server <- function(input, output){
  # Define login module
  credentials <- shinyauthr::loginServer(
    id = 'login',
    data = user_base,
    user_col = user,
    pwd_col = password_hash,
    sodium_hashed = TRUE,
    cookie_logins = TRUE,
    sessionid_col = sessionid,
    cookie_getter = get_sessions_from_db,
    cookie_setter = add_session_to_db,
    log_out = shiny::reactive(logout_init())
  )
  
  # Define logout module
  logout_init <- shinyauthr::logoutServer(
    id = 'logout',
    active = shiny::reactive(credentials()$user_auth)
  )
    
  # Define reactive function
  filter_users <- shiny::reactive({
    users %>%
      # Add career stage pickerInput filter
      dplyr::filter(`Current career stage` %in% input$career) %>%
      # Add primary subfield pickerInput filter
      dplyr::filter(`Primary subfield` %in% input$primary) %>%
      # Add secondary subfield pickerInput filter
      dplyr::filter(`Secondary subfield` %in% input$secondary)
  })
  
  # Define reactive dataTable
  output$filterusers <- DT::renderDataTable({
    DT::datatable(filter_users(), rownames = FALSE,
                  options = list(paging = TRUE, pageLength = 5,
                                 columnDefs = list(list(targets = c(1:16), width = '5em')),
                                 autoWidth = TRUE, scrollX = TRUE))
  })
  
  # Define insert function
  my.insert.callback <- function(data, row){
    # Append row to data frame
    my_users <- rbind(data, row)
    
    # Overwrite data frame to sheet
    googlesheets4::sheet_write(data = my_users, ss = responses_id, sheet = 'Sheet1')
    
    # View data frame
    return(my_users)
  }
  
  # Define update function
  my.update.callback <- function(data, olddata, row){
    # Update row in data frame
    my_users[row,] <- data[row,]
    
    # Overwrite data frame to sheet
    googlesheets4::sheet_write(data = my_users, ss = responses_id, sheet = 'Sheet1')
    
    # View data frame
    return(my_users)
  }
  
  # Define delete function
  my.delete.callback <- function(data, row){
    # Delete row in data frame
    my_users[row,] <- my_users[-row,]
    
    # Overwrite data frame to sheet
    googlesheets4::sheet_write(data = my_users, ss = responses_id, sheet = 'Sheet1')
    
    # View data frame
    return(my_users)
  }
  
  # Create DTedit object
  DTedit::dtedit_server(
    id = 'editusers',
    thedata = my_users,
    view.cols = names(my_users)[c(1:3)],
    edit.cols = names(my_users)[c(1:17)],
    edit.label.cols = names(my_users)[c(1:17)],
    input.types = my_inputs,
    input.choices = my_input_choices,
    callback.update = my.update.callback,
    callback.insert = my.insert.callback,
    callback.delete = my.delete.callback)
  
  # Define UI output
  output$trigUI <- renderUI({
    # Define credentials
    shiny::req(credentials()$user_auth)
    
    # Define fluidPage
    fluidPage(
      # Define fluidRow
      fluidRow(
        column(width = 12,
               # Add instructions text
               box(width = NULL, includeMarkdown('text/instructions.md')))),
      # Define fluidRow
      fluidRow(
        column(width = 12,
               # Add reactive editable DataTable
               box(width = NULL, DTedit::dtedit_ui('editusers')))))
  })
}