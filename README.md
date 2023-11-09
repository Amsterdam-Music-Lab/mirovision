# Measuring the Eurovision Song Contest: A Living Dataset for Real-World MIR

This repository contains the materials to reproduce results reported in:

* [Measuring the Eurovision Song Contest: A Living Dataset for Real-World MIR](https://ismir2023program.ismir.net/poster_276.html)

* [Paper on ISMIR Archive](https://archives.ismir.net/ismir2023/paper/000097.pdf)

To access the repository that is used to manage and update the original dataset, please visit 

* [the eurovision-dataset repository](https://github.com/Spijkervet/eurovision-dataset).


## Data 

Data that comprise the MIRoVision dataset originates from three primary sources:

1. [Official Eurovison website](https://eurovision.tv/)
2. [Eurovision World fan website](https://eurovisionworld.com)
3. audio features taken directly from the final live performances.

The dataset contains five primary types of data: 

1. contest meta-data; 
2. contest results; 
3. voting data; 
4. audio features extracted from recorded performances of the musical acts; and 
5. betting-office (bookmakers') data.

We provide CSV and RDS (R data) formats.

### Contest Meta-Data and Results

Contest meta-data and results are available in `contestants.csv` and `contestants.rda` in the `data` folder.
In addition to the song and performer from each country and year, the meta-data includes composers, lyricists, lyrics, running order, and a link to the YouTube video of the final performance (as maintained by the Eurovision World team).

### Voting Data

The voting data is stored in two separate tables.

  - The `votes` table contains data from the contest's beginning in 1956 and indicates how each country's jury and televoting points were distributed to each other participating country.
  
  - The `jurors` table contains data beginning from the year 2016 and indicates how each the five anonymous jurors *within* each country's jury (designated with letter names A through E) ranked the performances. Note that individual jurors are required to rank every performance during a show except the performance from their own country: the well-known 12–10–8–7–6–5–4–3–2–1 point system is derived after averaging the full rankings of each country's jurors. 

### Audio Features 

Although the MERT features are proprietary, we provide the TUNe+ features used in the paper in the `tune_plus` table.
It is also possible to compute Essentia features by navigating to [the dataset repository](https://github.com/Spijkervet/eurovision-dataset) and following the instructions under the [Audio Features](https://github.com/Spijkervet/eurovision-dataset#audio-features) heading.  

### Betting Office Data

In addition to the voting tables, the `bookmakers` table provides tables of historical bookmakers' odds for the contest winners, as collected by Eurovision World.
The Eurovision Song Contest is a popular target for online betting.
Day-of-contest odds are available for 2016 and 2017, and daily odds up to six months prior to the contest are available from 2018 onward, for between 10 and 20 betting offices.

## Figures

### Figure 1

![Figure 1](figures/figure1.png)

Correspondence between song competitiveness (in cantobels) and final Eurovision Song Contest scores in 2019. The pattern in this year is typical of all other years, with a relatively slow increase in points as competitiveness improves up to about 0.5~cantobels, followed by a rapid increase. Because of the semi-final rounds, the relationship between competitiveness and final score is not a strictly monotonic as in years without semi-finals, but it is still nearly monotonic.

### Figure 2

![Figure 2](figures/figure2.png)

Historical competitiveness of Eurovision Song Contest entries (in cantobels). Countries are coloured by their geographic region as defined in the United Nations M49 standard. Winners are boxed. The standard error of estimates is roughly 0.5 cantobel in early years and roughly 0.3 after the institution of semi-final rounds in 2004; as such, difference of approximately 1.0 cantobels are likely statistically significant. After a period when Northern and Western Europe exchanged victories, there was a period of Northern European dominance; recent years have been characterised by a good geographic diversity of winners.

### Figure 3

![Figure 3](figures/figure3.png)

Median competitiveness of countries' Eurovision Song Contest entries, 1975--2022, in cantobels with 90% credible intervals.
Countries are coloured by their geographic region as defined in the United Nations M49 standard.
Ukraine, Russia, Italy, and Sweden stand out as having sent contestants of exceptional competitiveness, although Azerbaijan, the United Kingdom, and Greece's credible intervals are also strictly greater than zero.

### Figure 4

<img src="figures/figure4.png" alt="ideal scoring for judges" width="500"/>

Ideal scores for averaging ranks within juries, according to a generalised partial-credit model, with 90% credible intervals. In recent years, the Eurovision Song Contest has used an exponential weighting scheme, but these results suggest that a linear scheme with a small bonus for the top-ranked entry would be sufficient.

## Modeling Code

The models used in the paper can be found under `stan`. 

## Cite

When using these materials please the following resources:

### Paper

```

@inproceedings{burgoyne_mirovision,
    author       = {John Ashley Burgoyne and Janne Spijkervet and David John Baker},
    title        = {Measuring the {Eurovision Song Contest}: A Living Dataset for Real-World {MIR}},
    booktitle    = {Proceedings of the 24th International Society for Music Information Retrieval Conference},
    year         = 2023,
    address      = {Milan, Italy},
    url          = {https://archives.ismir.net/ismir2023/paper/000097.pdf}
}

```

### Dataset

```

@misc{spijkervet_eurovision,
    author       = {Janne Spijkervet},
    title        = {The {Eurovision} Dataset},
    month        = mar,
    year         = 2020,
    doi          = {10.5281/zenodo.4036457},
    version      = {1.0},
    publisher    = {Zenodo},
    url          = {https://zenodo.org/badge/latestdoi/214236225}
}

```

