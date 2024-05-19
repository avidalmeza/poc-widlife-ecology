# Define header
header <- shinydashboard::dashboardHeader(
  title = 'POC in Wildlife Ecology',
  # Add logout button
  tags$li(
    class = 'dropdown',
    style = 'padding: 8px;',
    shinyauthr::logoutUI('logout')
    )
)

# Define sidebar 
sidebar <- shinydashboard::dashboardSidebar(
  # Define sidebarMenu
  sidebarMenu(
    menuItem('About', tabName = 'about'),
    menuItem('Database', tabName = 'database'),
    menuItem('Returning User', tabName = 'returning')
  )
)

# Define body
body <- shinydashboard::dashboardBody(
  # Link stylesheet
  includeCSS('www/styles.css'),
  tabItems(
    tabItem(
      # About tabItem ----
      tabName = 'about',
      # Define fluidPage
      fluidPage(
        # Add banner image
        tags$img(class = 'banner', src = 'images/IMG_3992.jpg'),
        # Define fluidRow
        fluidRow(
          column(width = 8,
                 # Add about text
                 box(width = NULL, includeMarkdown('text/about.md'))
                 ),
          column(width = 4,
                 # Add join text
                 box(width = NULL, includeMarkdown('text/join.md')),
                 # Add edit text
                 box(width = NULL, includeMarkdown('text/edit.md'))
                 )
          )
        )
      ),
    tabItem(
      # Database tabItem ----
      tabName = 'database',
      # Define fluidPage
      fluidPage(
        # Define fluidRow
        fluidRow(
          column(width = 4,
                 # Add career pickerInput
                 box(width = NULL,
                     shinyWidgets::pickerInput('career', label = 'Select Career Stage:',
                                               choices = unique(users$`Current career stage`),
                                               selected = unique(users$`Current career stage`),
                                               options = pickerOptions(actionsBox = TRUE), multiple = T)
                     )
                 ),
              column(width = 4,
                     # Add primary subfield pickerInput
                     box(width = NULL,
                         shinyWidgets::pickerInput('primary', label = 'Select Primary Subfield:',
                                                   choices = unique(users$`Primary subfield`),
                                                   selected = unique(users$`Primary subfield`),
                                                   options = pickerOptions(actionsBox = TRUE), multiple = T)
                         )
                     ),
              column(width = 4,
                     # Add secondary subfield pickerInput
                     box(width = NULL,
                         shinyWidgets::pickerInput('secondary', label = 'Select Secondary Subfield:',
                                                   choices = unique(na.omit(users$`Secondary subfield`)),
                                                   selected = unique(na.omit(users$`Secondary subfield`)),
                                                   options = pickerOptions(actionsBox = TRUE), multiple = T)
                         )
                     )
              ),
            # Define fluidRow
            fluidRow(
              column(width = 12,
                     # Add reactive DataTable
                     box(width = NULL, DT::DTOutput('filterusers', width = '100%'))
                     )
              )
        )
      ),
    tabItem(
      # Returning tabItem ----
      tabName = 'returning',
      # Define login panel UI function
      shinyauthr::loginUI(id = 'login', cookie_expiry = cookie_expiry),
      # Add UI output
      fluidRow(
        column(width = 12, shiny::uiOutput('trigUI'))
        )
      )
    )
  )

# Define user interface
shinydashboard::dashboardPage(header, sidebar, body)