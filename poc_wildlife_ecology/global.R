library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(shinyauthr)
library(shinyalert)
library(jsonlite)
library(tidyverse)
library(lubridate)
library(gargle)
library(googledrive)
library(googlesheets4)
library(markdown)
library(RSQLite)
library(DBI)
library(DT)
library(DTedit)

# Obtain Google Accounts email
email <- Sys.getenv('email')

# Obtain Google Sheets IDs
responses_id <- googledrive::as_id(Sys.getenv('responses')) # POC in Wildlife Ecology (Responses) 
login_id <- googledrive::as_id(Sys.getenv('login')) # POC in Wildlife Ecology - Login
schema_id <- googledrive::as_id(Sys.getenv('schema')) # POC in Wildlife Ecology - Schema

# Set web app flow  
options(gargle_oauth_client_type = 'web')

# Set non-interactive authentication
options(gargle_oauth_cache = '.secrets')
googlesheets4::gs4_auth(cache = '.secrets', email = TRUE)

# Set non-interactive authentication with service account
# path <- c('poc_wildlife_ecology/service_account.json')
# scope <- c('https://www.googleapis.com/auth/spreadsheets')
# token_obj <- gargle::credentials_service_account(path = path, scopes = scope)
# googlesheets4::gs4_auth(token = token_obj)

# Read Google Sheets
responses <- googlesheets4::read_sheet(responses_id) # POC in Wildlife Ecology (Responses)
new_responses <- googlesheets4::read_sheet(responses_id, sheet = 'Copy') # POC in Wildlife Ecology (Responses)
login <- googlesheets4::read_sheet(login_id) # POC in Wildlife Ecology - Login
input_types <- googlesheets4::read_sheet(schema_id, sheet = 1) # POC in Wildlife Ecology - Schema
schema <- googlesheets4::read_sheet(schema_id, sheet = 2) # POC in Wildlife Ecology - Schema

# Define number of days for cookie expiration
cookie_expiry <- 7

# Define function to retrieve sessions from database
get_sessions_from_db <- function(conn = db, expiry = cookie_expiry){
  # Return data frame
  DBI::dbReadTable(conn, 'sessions') %>%
    mutate(login_time = lubridate::ymd_hms(login_time)) %>%
    as_tibble() %>%
    filter(login_time > lubridate::now() - lubridate::days(expiry))
}

# Define function to add a session to database
add_session_to_db <- function(user, sessionid, conn = db){
  tibble(
    user = user, 
    sessionid = sessionid, 
    login_time = as.character(now())) %>%
    DBI::dbWriteTable(conn, 'sessions', ., append = TRUE)
}

# Connect to SQLite database
db <- DBI::dbConnect(SQLite(), ':memory:')

# Create table in SQLite database
DBI::dbCreateTable(db, 'sessions', c(user = 'TEXT', sessionid = 'TEXT', login_time = 'TEXT'))

# Define userbase
user_base <- tibble(
  user = login$Username,
  password = login$Password,
  password_hash = sapply(login$Password, sodium::password_store))

# Extract   
users <- responses %>%
  # Select columns by index position
  select(c(2:18)) %>%
  # Rename column
  rename(`Email address` = `Email Address`)

# Convert to data frame
my_users <- as.data.frame(users)
my_returning_users <- as.data.frame(new_responses)

# Define input type vector
my_inputs <- input_types$`Input Type`

# Assign names to input type vector 
names(my_inputs) <- names(my_users)[c(1:17)]

# Define input choices
# na.omit() - remove missing values in object
# unlist() - flatten list to vector, satisfy data class for input type
my_input_choices <- list(
  `Country` = unlist(na.omit(schema$Country)),
  `Current or intended career type` = unlist(na.omit(schema$`Current or intended career type`)),
  `Current career stage` = unlist(na.omit(schema$`Current career stage`)),
  # `I identify as` = unlist(na.omit(schema$`I identify as`)),
  `Pimary subfield` = unlist(na.omit(schema$Subfield)),
  `Secondary subfield` = unlist(na.omit(schema$Subfield))
)

# Assign names to input type vector 
names(my_input_choices) <- names(my_users)[c(8:10, 12:13)]