try(dev.off(dev.list()["RStudioGD"]), silent=TRUE)
rm(list = ls())
gc()

# load libraries
library("tidyverse")
library("pdftools") # handles pdf files
library("plotly") # for plotting, includes choropleth maps
library("shiny") # to create dashboards

# load data
temp_file <- tempfile() # allocates memory for a temp file
url <- "https://hdr.undp.org/system/files/documents//hdr2020pdf.pdf"
download.file(url, temp_file) # downloads the file into the temp_file variable
txt <- pdf_text(temp_file) # extracts the text from the temp_file
file.remove(temp_file) # deletes the temp_file
rm(temp_file, url)

# txt is a char vector with an entry per page, we only keep page 2
hdi_trends <- txt[361:364]
# it is a long string
# hdi_trends %>% head
tab <- str_split(hdi_trends, "\n")
rm(hdi_trends, txt)

# inspect page 1
tab[[1]]
col_names <- tab[[1]][9]
col_names

# find column names in the text
# let us use regular expressions to remove letters and spaces, then split
col_names <- col_names %>%
  str_trim() %>%
  str_replace_all("[a-zA-Z]+", "") %>%
  str_split("\\s{2,}", simplify = TRUE)
col_names <- col_names[, 2:9]
col_names <- c('Country', col_names)
col_names

# find data for a single country
# let us inspect a single line
first_country <- tab[[1]][11]
first_country <- first_country %>%
  str_trim() %>%
  str_split("\\s{2,}", simplify = TRUE)
first_country_name <- first_country[1,1] %>%
  str_replace_all("[0-9]+", "") %>%
  str_trim()
first_country <- c(first_country_name, first_country[, 2:10])
first_country
rm(first_country, first_country_name)

# create empty data set and set column names
hdi <- data.frame(matrix(ncol = length(col_names), nrow = 0), stringsAsFactors = FALSE)
colnames(hdi) <- col_names
rm(col_names)

# append data from first page
for(i in 11:72) {
  country_data <- tab[[1]][i] %>%
    str_trim() %>%
    str_replace_all("\\.\\.", "NA") %>%
    str_split("\\s{2,}", simplify = TRUE)
  country_name <- country_data[1,1] %>%
    str_replace_all("[0-9]+", "") %>%
    str_trim()
  country_row <- c(country_name, country_data[, 2:9])
  hdi[nrow(hdi) + 1,] <- country_row
}

# append data from second page
for(i in c((10:13), (15:67), (69:72)) ) {
  country_data <- tab[[2]][i] %>%
    str_trim() %>%
    str_replace_all("\\.\\.", "NA") %>%
    str_split("\\s{2,}", simplify = TRUE)
  country_name <- country_data[1,1] %>%
    str_replace_all("[0-9]+", "") %>%
    str_trim()
  country_row <- c(country_name, country_data[, 2:9])
  hdi[nrow(hdi) + 1,] <- country_row
}

# append data from third page
for(i in c((10:42), (44:72)) ) {
  country_data <- tab[[3]][i] %>%
    str_trim() %>%
    str_replace_all("\\.\\.", "NA") %>%
    str_split("\\s{2,}", simplify = TRUE)
  country_name <- country_data[1,1] %>%
    str_replace_all("[0-9]+", "") %>%
    str_trim()
  country_row <- c(country_name, country_data[, 2:9])
  hdi[nrow(hdi) + 1,] <- country_row
}

# append data from fourth page
for(i in 10:13) {
  country_data <- tab[[4]][i] %>%
    str_trim() %>%
    str_replace_all("\\.\\.", "NA") %>%
    str_split("\\s{2,}", simplify = TRUE)
  country_name <- country_data[1,1] %>%
    str_replace_all("[0-9]+", "") %>%
    str_trim()
  country_row <- c(country_name, country_data[, 2:9])
  hdi[nrow(hdi) + 1,] <- country_row
}



# sample data set that contains three-letter ISO country codes
# we will need these codes for plotting choropleth world maps
codes_df <- read.csv("https://raw.githubusercontent.com/plotly/datasets/master/2014_world_gdp_with_codes.csv")
codes_df <- codes_df %>%
  select(COUNTRY, CODE)

# identify mismatching names (written with different conventions)
cat('Number of mismatching country names\n')
length(hdi$Country[!(hdi$Country %in% codes_df$COUNTRY)])
cat('Mismatching names as written in the hdi data.frame\n')
hdi$Country[!(hdi$Country %in% codes_df$COUNTRY)]
cat('Mismatching names as written in the codes_df data.frame\n')
codes_df$COUNTRY[!(codes_df$COUNTRY %in% hdi$Country)]

# we fix them manually since they are few, and non trivial
hdi$Country[which(hdi$Country == 'Bahamas')] <- 'Bahamas, The'
hdi$Country[which(hdi$Country == 'Bolivia (Plurinational State of)')] <- 'Bolivia'
hdi$Country[which(hdi$Country == 'Brunei Darussalam')] <- 'Brunei'
hdi$Country[which(hdi$Country == 'Congo')] <- 'Congo, Republic of the'
hdi$Country[which(hdi$Country == 'Congo (Democratic Republic of the)')] <- 'Congo, Democratic Republic of the'
hdi$Country[which(hdi$Country == 'Côte d’Ivoire')] <- "Cote d'Ivoire"
hdi$Country[which(hdi$Country == 'Czechia')] <- 'Czech Republic'
hdi$Country[which(hdi$Country == 'Gambia')] <- 'Gambia, The'
hdi$Country[which(hdi$Country == 'Hong Kong, China (SAR)')] <- 'Hong Kong'
hdi$Country[which(hdi$Country == 'Iran (Islamic Republic of)')] <- 'Iran'
hdi$Country[which(hdi$Country == 'Korea (Republic of)')] <- 'Korea, South'
hdi$Country[which(hdi$Country == 'Lao People’s Democratic Republic')] <- 'Laos'
hdi$Country[which(hdi$Country == 'Micronesia (Federated States of)')] <- 'Micronesia, Federated States of'
hdi$Country[which(hdi$Country == 'Moldova (Republic of)')] <- 'Moldova'
hdi$Country[which(hdi$Country == 'Myanmar')] <- 'Burma'
hdi$Country[which(hdi$Country == 'North Macedonia')] <- 'Macedonia'
hdi$Country[which(hdi$Country == 'Russian Federation')] <- 'Russia'
hdi$Country[which(hdi$Country == 'Syrian Arab Republic')] <- 'Syria'
hdi$Country[which(hdi$Country == 'Tanzania (United Republic of)')] <- 'Tanzania'
hdi$Country[which(hdi$Country == 'Venezuela (Bolivarian Republic of)')] <- 'Venezuela'
hdi$Country[which(hdi$Country == 'Viet Nam')] <- 'Vietnam'

# merge data frames to include 3-letter ISO country codes in the HDI data frame
df <- merge(x = hdi, y = codes_df, by.x = 'Country', by.y = 'COUNTRY', all.x = TRUE)

# Countries/territories whose 3-letter ISO country codes not in codes_df
missing <- df$Country[which(is.na(df$CODE))]

# fix missing values based on https://www.iban.com/country-codes
df$CODE[which(df$Country == missing[1])] <- 'SWZ'
df$CODE[which(df$Country == missing[2])] <- 'PSE'



# Shiny Dashboard

# Define UI for app that draws a histogram ----
ui <- fluidPage(
  # App title
  titlePanel("Time evolution of the Human Development Index [HDI]"),
  # Sidebar layout
  sidebarLayout(
    # Sidebar panel
    sidebarPanel(
      h4("Please, select a year to plot the world map:"),
      # Input: Selector for df column to display
      selectInput("year",
                  NULL,
                  choices = colnames(df)[2:9],
                  selected = 0
                  ),
      h4("Select a country/territory to see its HDI time evolution"),
      # Input: Selector for country name
      selectInput("country",
                  NULL,
                  choices = df$Country,
                  selected = 0
      ),
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      # Output: Plot_ly figure
      plotlyOutput("map"),
      br(),
      plotlyOutput("time_graph")
    )
  )
)

server <- function(input, output) {
  # world map for the year selected by the user
  output$map <- renderPlotly({
    year <- input$year
    fig <- plot_ly(df,
                   type = 'choropleth',
                   locations = df$CODE,
                   z = df[[`year`]],
                   zmin = 0,
                   zmax = 1,
                   text = df$Country,
                   colorscale = "Viridis" )
    fig <- fig %>% colorbar(title = "HDI")
    fig <- fig %>%
      layout(
        title = str_c(year," Human Development Index"),
        geo = list(showlakes = TRUE, lakecolor = toRGB('white'))
      )
    fig
  })
  # HDI time-evolution scatter plot
  output$time_graph <- renderPlotly({
    name <- input$country
    time_data <- df[which(df$Country == name), ] %>%
      gather(year, hdi, '1990':'2019') %>%
      select(year, hdi)
    time_data$hdi <- time_data$hdi %>%
      str_replace_all('[a-zA-Z]+', '-')
    numeric_index <- which(time_data$hdi != '-')
    fig <- plot_ly(time_data,
                   x = time_data$year[numeric_index],
                   y = time_data$hdi[numeric_index],
                   type = 'scatter',
                   mode = 'lines+markers',
                   marker = list(size = 10)
                   )
    fig <- fig %>%
      layout(
        title = str_c('Time evolution of the HDI of ', name),
        yaxis = list(title = 'Year'),
        xaxis = list(title = 'HDI value', zeroline = FALSE)
        )
    fig
  })
}

shinyApp(ui, server)
