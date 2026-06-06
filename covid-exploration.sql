-- ================================================
-- COVID DATA EXPLORATION
-- Author: Fehintola
-- Date: 2026
-- Data Source: Our World In Data
-- ================================================

-- TASK 1: UK Cases and Deaths Over Time
SELECT 
    location,
    date,
    total_cases,
    total_deaths
FROM covid_deaths
WHERE location = 'United Kingdom'
ORDER BY date;

-- TASK 2: Death Percentage Over Time
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    ROUND((total_deaths/total_cases * 100)::NUMERIC, 2) 
        AS death_percentage
FROM covid_deaths
WHERE location = 'United Kingdom'
ORDER BY date;

-- TASK 3: Top 10 Countries By Total Cases
SELECT 
    location,
    population,
    MAX(total_cases) AS highest_total_cases
FROM covid_deaths
WHERE total_cases IS NOT NULL
GROUP BY location, population
ORDER BY MAX(total_cases) DESC
LIMIT 10;

-- TASK 4: Infection Rate Per Population
SELECT 
    location,
    population,
    MAX(total_cases) AS highest_total_cases,
    ROUND((MAX(total_cases)/population * 100)::NUMERIC, 2) 
        AS infection_rate
FROM covid_deaths
WHERE total_cases IS NOT NULL
GROUP BY location, population
ORDER BY infection_rate DESC
LIMIT 10;

-- TASK 5: Death Count Per Continent
SELECT 
    location,
    MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NULL
AND location NOT IN (
    'World',
    'European Union',
    'International',
    'High income',
    'Upper middle income',
    'Lower middle income',
    'Low income'
)
GROUP BY location
ORDER BY total_death_count DESC;

-- TASK 6: JOIN Deaths and Vaccinations
SELECT 
    dea.location,
    dea.date,
    dea.population,
    dea.total_deaths,
    vac.new_vaccinations
FROM covid_deaths AS dea
LEFT JOIN covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- TASK 7: Rolling Vaccination Total Using CTE
WITH vaccination_data AS (
    SELECT 
        dea.location,
        dea.date,
        dea.population,
        dea.total_deaths,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS rolling_vaccinations
    FROM covid_deaths AS dea
    LEFT JOIN covid_vaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
    ROUND((rolling_vaccinations/population * 100)::NUMERIC, 2) 
        AS percent_vaccinated
FROM vaccination_data
ORDER BY location, date;

-- TASK 8: Create VIEW
CREATE VIEW percent_population_vaccinated AS
SELECT 
    dea.location,
    dea.date,
    dea.population,
    dea.total_deaths,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS rolling_vaccinations
FROM covid_deaths AS dea
LEFT JOIN covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- ================================================
-- ORIGINAL ANALYSIS
-- ================================================

-- CHAPTER 1A: Death Rates Before vs After Vaccines
SELECT 
    location,
    ROUND(AVG(CASE 
        WHEN date < '2021-01-01' 
        THEN (total_deaths/total_cases * 100) 
    END)::NUMERIC, 2) AS avg_death_rate_before_vaccines,
    ROUND(AVG(CASE 
        WHEN date >= '2021-01-01' 
        THEN (total_deaths/total_cases * 100) 
    END)::NUMERIC, 2) AS avg_death_rate_after_vaccines
FROM covid_deaths
WHERE continent IS NOT NULL
AND total_cases > 1000
GROUP BY location
ORDER BY avg_death_rate_before_vaccines DESC;

-- CHAPTER 1B: Countries Where Death Rates Increased After Vaccines
SELECT 
    location,
    ROUND(AVG(CASE 
        WHEN date < '2021-01-01' 
        THEN (total_deaths/total_cases * 100) 
    END)::NUMERIC, 2) AS avg_death_rate_before_vaccines,
    ROUND(AVG(CASE 
        WHEN date >= '2021-01-01' 
        THEN (total_deaths/total_cases * 100) 
    END)::NUMERIC, 2) AS avg_death_rate_after_vaccines,
    ROUND(AVG(CASE 
        WHEN date >= '2021-01-01' 
        THEN (total_deaths/total_cases * 100) 
    END)::NUMERIC, 2) - 
    ROUND(AVG(CASE 
        WHEN date < '2021-01-01' 
        THEN (total_deaths/total_cases * 100) 
    END)::NUMERIC, 2) AS death_rate_change
FROM covid_deaths
WHERE continent IS NOT NULL
AND total_cases > 1000
GROUP BY location
HAVING 
    AVG(CASE WHEN date >= '2021-01-01' 
        THEN (total_deaths/total_cases * 100) END) >
    AVG(CASE WHEN date < '2021-01-01' 
        THEN (total_deaths/total_cases * 100) END)
ORDER BY death_rate_change DESC;

-- CHAPTER 1C: Global Vaccine Impact Summary
WITH death_rate_comparison AS (
    SELECT 
        location,
        AVG(CASE 
            WHEN date < '2021-01-01' 
            THEN (total_deaths/total_cases * 100) 
        END) AS avg_death_rate_before_vaccines,
        AVG(CASE 
            WHEN date >= '2021-01-01' 
            THEN (total_deaths/total_cases * 100) 
        END) AS avg_death_rate_after_vaccines
    FROM covid_deaths
    WHERE continent IS NOT NULL
    AND total_cases > 1000
    GROUP BY location
)
SELECT 
    CASE 
        WHEN avg_death_rate_after_vaccines > avg_death_rate_before_vaccines 
        THEN 'Death Rate Increased'
        ELSE 'Death Rate Decreased'
    END AS vaccine_impact,
    COUNT(*) AS number_of_countries,
    ROUND((COUNT(*) * 100.0 / 177), 1) AS percentage_of_world
FROM death_rate_comparison
GROUP BY 
    CASE 
        WHEN avg_death_rate_after_vaccines > avg_death_rate_before_vaccines 
        THEN 'Death Rate Increased'
        ELSE 'Death Rate Decreased'
    END;
	
-- CHAPTER 2: Vaccination Speed vs Death Rates
--CHAPTER 2: Did Countries that vaccinated faster loose fewer people?
--the first CTE is to determine the top 20 countries who gave vaccines earliest
--the second CTE is to know the overall average death rate per country across the whole pandemi
WITH vaccination_speed AS (
    SELECT 
        dea.location,
        dea.population,
        MIN(dea.date) AS date_reached_10_percent
    FROM covid_deaths AS dea
    JOIN covid_vaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
    AND (vac.people_vaccinated/dea.population) * 100 >= 10
    GROUP BY dea.location, dea.population
),
death_rates AS (
    SELECT 
        dea.location,
        ROUND(AVG(
            dea.total_deaths / NULLIF(dea.total_cases, 0) * 100
        )::NUMERIC, 2) AS overall_death_rate
    FROM covid_deaths AS dea
    WHERE dea.continent IS NOT NULL
    AND dea.total_cases > 1000
    GROUP BY dea.location
)
SELECT 
    CASE 
        WHEN vs.date_reached_10_percent < '2021-02-01' 
        THEN 'Fast Vaccinator'
        WHEN vs.date_reached_10_percent < '2021-03-15' 
        THEN 'Medium Vaccinator'
        ELSE 'Slow Vaccinator'
    END AS vaccination_speed_category,
    COUNT(*) AS number_of_countries,
    ROUND(AVG(dr.overall_death_rate)::NUMERIC, 2) AS avg_death_rate,
    ROUND(MIN(dr.overall_death_rate)::NUMERIC, 2) AS lowest_death_rate,
    ROUND(MAX(dr.overall_death_rate)::NUMERIC, 2) AS highest_death_rate
FROM vaccination_speed vs
LEFT JOIN death_rates dr
    ON vs.location = dr.location
GROUP BY 
    CASE 
        WHEN vs.date_reached_10_percent < '2021-02-01' 
        THEN 'Fast Vaccinator'
        WHEN vs.date_reached_10_percent < '2021-03-15' 
        THEN 'Medium Vaccinator'
        ELSE 'Slow Vaccinator'
    END
ORDER BY avg_death_rate ASC;


WITH vaccination_speed AS (
    SELECT 
        dea.location,
        dea.population,
        MIN(dea.date) AS date_reached_10_percent
    FROM covid_deaths AS dea
    JOIN covid_vaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
    AND (vac.people_vaccinated/dea.population) * 100 >= 10
    GROUP BY dea.location, dea.population
)
SELECT 
    MIN(date_reached_10_percent) AS earliest,
    MAX(date_reached_10_percent) AS latest,
    COUNT(*) AS total_countries
FROM vaccination_speed;


--CHAPTER 3-What was the cost of low vaccination 
-- — what happened in countries that never reached 10% vaccination?
SELECT 
    'Never Reached 10% Vaccination' AS vaccination_group,
    COUNT(DISTINCT dea.location) AS number_of_countries,
    ROUND(AVG(dea.total_deaths/NULLIF(dea.population,0)*100)::NUMERIC,2) 
        AS avg_death_rate,
    ROUND(AVG(dea.total_cases/NULLIF(dea.population, 0)*100)::NUMERIC,2) 
        AS avg_infection_rate
FROM covid_deaths AS dea
WHERE dea.continent IS NOT NULL
AND dea.total_cases > 1000
AND dea.location NOT IN (
    SELECT dea2.location
    FROM covid_deaths AS dea2
    JOIN covid_vaccinations AS vac
        ON dea2.location = vac.location
        AND dea2.date = vac.date
    WHERE dea2.continent IS NOT NULL
    AND (vac.people_vaccinated/dea2.population) * 100 >= 10
)
UNION ALL
--countries that did reach 10% vaccination.
SELECT 
    'Reached 10% Vaccination' AS vaccination_group,
    COUNT(DISTINCT dea.location) AS number_of_countries,
    ROUND(AVG(dea.total_deaths/NULLIF(dea.population,0)*100)::NUMERIC,2) 
        AS avg_death_rate,
    ROUND(AVG(dea.total_cases/NULLIF(dea.population,0)*100)::NUMERIC,2) 
        AS avg_infection_rate
FROM covid_deaths AS dea
WHERE dea.continent IS NOT NULL
AND dea.total_cases > 1000
AND dea.location IN (
    SELECT dea2.location
    FROM covid_deaths AS dea2
    JOIN covid_vaccinations AS vac
        ON dea2.location = vac.location
        AND dea2.date = vac.date
    WHERE dea2.continent IS NOT NULL
    AND (vac.people_vaccinated/dea2.population) * 100 >= 10
);


--CHAPTER 4
--Did countries with more hospital beds have lower death rates?
--this test whether health care infrastructure not just vaccines determine who survived COVID
SELECT 
    CASE 
        WHEN vac.hospital_beds_per_thousand > 3 THEN 'Well Equipped'
        WHEN vac.hospital_beds_per_thousand >= 1 THEN 'Moderately Equipped'
        ELSE 'Poorly Equipped'
    END AS hospital_capacity,
    COUNT(DISTINCT dea.location) AS number_of_countries,
    ROUND(AVG(dea.total_deaths/NULLIF(dea.population,0)*100)::NUMERIC,2) 
        AS avg_death_rate,
    ROUND(AVG(dea.total_cases/NULLIF(dea.population,0)*100)::NUMERIC,2)
        AS avg_infection_rate,
    ROUND(AVG(vac.hospital_beds_per_thousand)::NUMERIC,2) 
        AS avg_hospital_beds
FROM covid_deaths AS dea
LEFT JOIN covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.total_cases > 1000
GROUP BY 
    CASE 
        WHEN vac.hospital_beds_per_thousand> 3 THEN 'Well Equipped'
        WHEN vac.hospital_beds_per_thousand >= 1 THEN 'Moderately Equipped'
        ELSE 'Poorly Equipped'
    END
ORDER BY avg_death_rate ASC;

--Did countries with older populations have higher COVID death rates?
SELECT 
    CASE 
        WHEN vac.median_age < 30 THEN 'Young Population'
        WHEN vac.median_age <= 40 THEN 'Middle Aged Population'
        ELSE 'Old Population'
    END AS age_category,
    COUNT(DISTINCT dea.location) AS number_of_countries,
    ROUND(AVG(dea.total_deaths/NULLIF(dea.population,0)*100)::NUMERIC,2) 
        AS avg_death_rate,
    ROUND(AVG(dea.total_cases/NULLIF(dea.population,0)*100)::NUMERIC,2)
        AS avg_infection_rate,
    ROUND(AVG(vac.median_age)::NUMERIC,2) 
        AS avg_median_age
FROM covid_deaths AS dea
LEFT JOIN covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.total_cases > 1000
GROUP BY 
    CASE 
        WHEN vac.median_age < 30 THEN 'Young Population'
        WHEN vac.median_age <= 40 THEN 'Middle Aged Population'
        ELSE 'Old Population'
    END
ORDER BY avg_death_rate ASC;

--Wealth vs Survival
WITH country_wealth AS (
    SELECT 
        dea.location,
        CASE 
            WHEN AVG(vac.gdp_per_capita) > 12000 THEN 'High Income'
            WHEN AVG(vac.gdp_per_capita) BETWEEN 2000 AND 12000 THEN 'Middle Income'
            ELSE 'Low Income'
        END AS wealth_category,
        ROUND(AVG(dea.total_deaths/NULLIF(dea.population,0)*100)::NUMERIC,2) 
            AS avg_death_rate,
        ROUND(AVG(dea.total_cases/NULLIF(dea.population,0)*100)::NUMERIC,2)
            AS avg_infection_rate,
        ROUND(AVG(vac.gdp_per_capita)::NUMERIC,2) 
            AS avg_gdp_per_capita
    FROM covid_deaths AS dea
    LEFT JOIN covid_vaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
    AND dea.total_cases > 1000
    GROUP BY dea.location
)
SELECT 
    wealth_category,
    COUNT(DISTINCT location) AS number_of_countries,
    ROUND(AVG(avg_death_rate)::NUMERIC,2) AS avg_death_rate,
    ROUND(AVG(avg_infection_rate)::NUMERIC,2) AS avg_infection_rate,
    ROUND(AVG(avg_gdp_per_capita)::NUMERIC,2) AS avg_gdp_per_capita
FROM country_wealth
GROUP BY wealth_category
ORDER BY avg_death_rate ASC;
