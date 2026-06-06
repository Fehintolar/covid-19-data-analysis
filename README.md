# COVID-19 Global Impact Analysis

## Project Overview
Comprehensive end-to-end analysis of global COVID-19 data covering 
177 countries from January 2020 to April 2021. Raw data was loaded 
into PostgreSQL, analysed using advanced SQL techniques, and 
visualised in an interactive Tableau Public dashboard.

## Interactive Dashboard
[View Full Dashboard on Tableau Public](https://public.tableau.com/views/Covid_visuals/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

## Tools Used
- **PostgreSQL 15** — data storage and querying
- **pgAdmin 4** — database management  
- **Tableau Public** — data visualisation
- **GitHub** — version control and documentation

## Data Source
Our World In Data — COVID-19 Dataset
https://ourworldindata.org/covid-deaths
- 85,171 rows across 177 countries
- January 2020 to April 2021

## Dataset Overview
| Table | Rows | Description |
|---|---|---|
| covid_deaths | 85,171 | Cases, deaths, population by country/date |
| covid_vaccinations | 85,171 | Vaccinations, hospital beds, GDP by country/date |

## Analysis Structure

### Base Exploration
- Death percentage by country over time
- Top 10 countries by total cases and infection rate
- Continental death counts adjusted for population
- Rolling vaccination totals using window functions
- Percentage of population vaccinated over time

### Chapter 1: Vaccination Effectiveness
**Question:** Did vaccines reduce death rates?

**Method:** Compared the average death rates before January 2021 (pre-vaccine) against those after January 2021 (post-vaccine) across all 177 countries using CASE WHEN and AVG aggregation.

**Finding:** Vaccines were associated with falling death rates in 68% of countries globally. The remaining 32% — led by Syria (+1.73%) and Yemen — saw increases concentrated in conflict zones where vaccines never arrived, reflecting access inequality rather than vaccine ineffectiveness.

### Chapter 2: Vaccination Speed vs Lives Saved
**Question:** Did faster vaccination save more lives?

**Method:** Used MIN(date) with a 10% population threshold to identify when each country first reached meaningful vaccination coverage, then compared death rates across speed categories.

**Finding:** Only 82 of 177 countries (46%) ever reached 10% vaccination. Israel vaccinated the fastest by December 2020. Medium speed vaccinators had the lowest average death rates at 2.11% — suggesting healthcare infrastructure quality mattered equally alongside vaccination speed.

### Chapter 3: The Unvaccinated World
**Question:** What was the cost of low vaccination?

**Method:** Used NOT IN subquery to identify 115 countries that never reached 10% vaccination and compared their outcomes against the 62 countries that did.

**Finding:** 115 countries — 65% of the world — never reached 10% vaccination. Direct comparison is complicated by severe data quality gaps between wealthy and poor nations, with poor nations systematically underreporting deaths.

### Chapter 4: Healthcare Infrastructure
**Question:** Did hospital beds determine survival?

**Method:** Categorised countries by hospital beds per thousand using CASE WHEN thresholds (>3 well-equipped, 1-3 moderate, <1 poorly equipped) and compared death and infection rates.

**Finding:** Well-equipped nations had 9x more hospital beds and successfully absorbed significantly higher patient loads. The 
consistent data quality bias — poorly equipped nations appearing statistically safer — reinforces the critical data quality finding.

### Original Query 1: Age Vulnerability
**Question:** Did older populations have higher death rates?

**Method:** Categorised 177 countries by median age into Young (below 30), Middle Aged (30-40) and Old (above 40) groups and compared death rates.

**Finding:** Countries with a median age above 40 had death rates 5x higher than countries below 30. This is the most statistically reliable finding — age demographics are consistently measured globally, unlike vaccination or death registration data.

### Original Query 2: Wealth vs Survival
**Question:** Did wealthier countries lose fewer people?

**Method:** Categorised countries by GDP per capita using World Bank thresholds (High >$12,000, Middle $2,000-$12,000, Low <$2,000) and compared death rates using a two-level CTE.

**Finding:** High-income nations showed 4x higher recorded death rates — reflecting better testing and reporting, not worse outcomes. The 22x GDP gap corresponds to a reporting quality gap. Wealth and age are correlated confounding variables throughout the dataset.

## Critical Data Quality Finding
A consistent pattern across all six analyses reveals that countries with the least healthcare infrastructure, lowest vaccination rates and most conflict systematically underreport COVID deaths — making them appear statistically safer when they were almost certainly more vulnerable. This finding appears consistently across every chapter and should be considered when interpreting all results.

## Key Findings Summary
| Analysis | Key Finding |
|---|---|
| Vaccination Effectiveness | 68% of countries saw death rates fall |
| Vaccination Speed | Only 46% of world reached 10% vaccination |
| Unvaccinated World | 65% of world never reached 10% vaccination |
| Healthcare Infrastructure | Well equipped nations had 9x more beds |
| Age Vulnerability | Older populations had 5x higher death rates |
| Wealth vs Survival | Wealth reflects reporting quality not mortality |
| Data Quality | Poor nations systematically underreport deaths |

## SQL Skills Demonstrated
- Complex multi-table JOINs
- Window functions for rolling totals (SUM OVER PARTITION BY)
- CTEs and multiple CTEs in a single query
- CASE WHEN categorisation and grouping
- Aggregate functions (MAX, AVG, MIN, COUNT, SUM)
- Subqueries with NOT IN and IN filtering
- UNION ALL for combining result sets
- NULLIF for division by zero prevention
- HAVING clause for filtering grouped results
- Database VIEW creation
- Data quality filtering and validation
- Type casting with:: NUMERIC

## Dashboard Structure
| Sheet | Chart Type | Key Question |
|---|---|---|
| Death Percentage Map | Filled Map | Where did COVID kill most? |
| Death Count By Continent | Bar Chart | Which continent lost the most? |
| Infection Rate Map | Filled Map | Where did COVID spread most? |
| Rolling Vaccinations | Line Chart | How did vaccination progress? |
| Vaccine Effectiveness | Bar Chart | Did vaccines reduce deaths? |
| Vaccine Impact Summary | Donut Pie Chart | Global vaccine impact split |
| Vaccination Speed | Bar Chart | Did speed save lives? |
| Unvaccinated World | Bar Chart | Cost of low vaccination |
| Healthcare Infrastructure | Packed Bubble Chart | Did hospital beds matter? |
| Age Vulnerability | Bar Chart | Did age determine survival? |
| Wealth vs Survival | Bar Chart | Did wealth determine survival? |

## Repository Structure
```
covid-19-data-analysis/
│
├── covid_exploration.sql    
├── README.md               
└── data/
    ├── global_death_numbers.csv
    ├── continent_death_counts.csv
    ├── infection_rate_by_country.csv
    ├── rolling_vaccinations.csv
    ├── death_rates_before_after_vaccines.csv
    ├── vaccine_impact_summary.csv
    ├── vaccination_speed_vs_deaths.csv
    ├── unvaccinated_world.csv
    ├── healthcare_infrastructure.csv
    ├── age_vulnerability.csv
    └── wealth_vs_survival.csv
```
