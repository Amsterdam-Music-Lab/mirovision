library(rvest)
library(stringr)
library(tidyverse)
library(useful)

# Goal: script to get juror level breakdown of each participating country (individual juror-level)

## Functions 

create_url <- function(city, year, night, act){
  url <- paste0("https://eurovision.tv/event/", city ,"-", year,"/", night, "/results/",  act )
  url
}


create_url_jury <- function(city, year, night){
  url <- paste0("https://eurovision.tv/event/", city ,"-", year,"/", night, "/jury")
  url
}


get_juror_data <- function(city, year, night, act){
  url <- create_url(city, year, night, act)
  
  x <- url |>
    read_html() |> 
    html_elements("div.container") %>%
    pluck(4) |>
    html_text2() |> 
    str_remove_all(pattern = "Detailed voting breakdown\nView the jury members\nCountry Juror A B C D E Jury rank Televoting rank ") |>
    str_replace_all(pattern = "([A-Z])", replacement = ",\\1") |>
    str_replace_all(pattern =  "United ,Kingdom", replacement = "UnitedKingdom") |>
    str_replace_all(pattern =  "North ,Macedonia", replacement = "NorthMacedonia") |>
    str_replace_all(pattern =  "Bosnia & ,Herzegovina", replacement = "BosniaHerzegovina") |>
    str_replace_all(pattern =  "San ,Marino", replacement = "SanMarino") |>
    str_remove(pattern = ",") |>
    str_split_1(pattern = ",") |>
    as_tibble() |>
    separate(col = value,
             into = c("Country","juror_A","juror_B","juror_C","juror_D","juror_E"), sep = " ") |>
    mutate(act = act,
           night = night,
           city = city,
           year = year)
  print(x, n = 1000)
}


yyy |>
  read_html() |>
  html_elements("div.country-name") |>
  html_text2()

get_jury_countries <- function(city, year, night){
  yyy <- create_url_jury(city, year, night )
  yyy |>
    read_html() |>
    html_elements("div.country-name") |>
    html_text2() |>
    stringr::str_to_lower() |>
    stringr::str_remove_all(pattern = "& ") |>
    stringr::str_replace_all(pattern = " ", replacement = "-")
}

get_jury_countries(city = "stockholm", year = "2016", night = "first-semi-final")

#-------------------------------------------------------------------------------
# Get Data 

create_jury_data <- function(city, year){
  
  # Get Jurors 
  esc_jurors_first <- get_jury_countries(city = city, year = year, night = "first-semi-final")
  esc_jurors_second <- get_jury_countries(city = city, year = year, night = "second-semi-final")
  esc_jurors_final <- get_jury_countries(city = city, year = year, night = "grand-final")
  
  n1 <- c()
  n2 <- c()
  n3 <- c()
  
  # First Night 
  for (i in esc_jurors_first) {
    n1[[i]] <- get_juror_data(city = city, year = year, night = "first-semi-final", act = i) 
  }
  
  # Second Night 
  for (i in esc_jurors_second) {
    n2[[i]] <- get_juror_data(city = city, year = year, night = "second-semi-final", act = i) 
  }
  
  # Third Night 
  for (i in esc_jurors_final) {
    n3[[i]] <- get_juror_data(city = city, year = year, night = "grand-final", act = i) 
  }
  
  all_nights <- rbind(do.call(rbind.data.frame, n1), do.call(rbind.data.frame, n2), do.call(rbind.data.frame, n3))
  
  all_nights
  
}

turin_2022 <- create_jury_data(city = "turin", year = "2022")
rotterdam_2021 <- create_jury_data(city = "rotterdam", year = "2021")
telaviv_2019 <- create_jury_data(city = "tel-aviv", year = "2019")
lisbon_2018 <- create_jury_data(city = "lisbon", year = "2018")
kyiv_2017 <- create_jury_data(city = "kyiv", year = "2017")
stockholm_2016 <- create_jury_data(city = "stockholm", year = "2016")

esc_voting_data <- rbind(stockholm_2016, kyiv_2017, lisbon_2018, telaviv_2019, rotterdam_2021, turin_2022)

esc_voting_data

write_csv(x = esc_voting_data, "esc-juror-level-data.csv")
