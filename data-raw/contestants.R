library(dplyr)
library(readr)
library(stringr)

contestants <-
  read_csv(
    "data-raw/contestants.dat",
    col_types =
      cols(
        .default = col_character(),
        year = col_integer(),
        to_country_id = col_character(),
        to_country = col_character(),
        sf_num = col_integer(),
        running_final = col_integer(),
        running_sf = col_integer(),
        place_final = col_integer(),
        points_final = col_integer(),
        place_sf = col_integer(),
        points_sf = col_integer(),
        points_tele_final = col_integer(),
        points_jury_final = col_integer(),
        points_tele_sf = col_integer(),
        points_jury_sf = col_integer()
      )
  ) |>
  transmute(
    year,
    country = str_to_upper(to_country_id),
    composers,
    lyricists,
    lyrics,
    song,
    performer,
    youtube_url,
    semifinal_number = sf_num,
    semifinal_running_order = running_sf,
    semifinal_jury_points = points_jury_sf,
    semifinal_televoting_points = points_tele_sf,
    semifinal_total_points = points_sf,
    semifinal_place = place_sf,
    final_running_order = running_final,
    final_jury_points = points_jury_final,
    final_televoting_points = points_tele_final,
    final_total_points = points_final
  )

write_csv(contestants, "data/CSV/contestants.csv")
saveRDS(contestants, file = "data/RDA/contestants.rda")
