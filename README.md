# UK Covid Data Exploration
***
![](Covidukimage.jpg)
***

# COVID-19 Data Exploration Using SQL
### United Kingdom Analysis with European Comparisons | 2020–2023

## Project Overview

This project explores reported COVID-19 cases, deaths and vaccination activity, focusing on the United Kingdom between 2020 and 2023. Selected European countries are also examined to provide a wider comparative context.

Using Excel for data preparation and SQL Server for analysis, I investigated cumulative reported cases and deaths, monthly changes, population-adjusted case counts and vaccination activity. I also created SQL views to support further reporting and visualisation.

## Objectives

The analysis aimed to:

- Explore reported COVID-19 cases and deaths in the United Kingdom.
- Examine monthly variations in reported cases and deaths during 2023.
- Calculate cumulative reported deaths as a percentage of cumulative reported cases.
- Compare reported case counts relative to population across European countries.
- Examine vaccination activity using cumulative dose calculations.
- Create reusable SQL views for reporting and visualisation.

## Tools and Skills

| Tool | Application |
|---|---|
| Microsoft Excel | Initial data cleaning and preparation |
| SQL Server / T-SQL | Data exploration, calculations and aggregation |
| SQL views | Reusable datasets for reporting and visualisation |

**SQL techniques demonstrated:** joins, common table expressions (CTEs), window functions, aggregate functions, explicit data conversion, date filtering and view creation.

## Data Source

The dataset was downloaded from [Our World in Data](https://ourworldindata.org/) and organised into two tables:

- **CovidDeaths:** population, reported cases and deaths.
- **CovidVaccinations:** vaccination records.

The main fields used included `location`, `continent`, `date`, `population`, `new_cases`, `total_cases`, `new_deaths`, `total_deaths` and `new_vaccinations`.

The intended UK study period is 2020–2023. However, several queries in the original script use all available records without a date restriction. These queries should be restricted to the study period before their outputs are presented as 2020–2023 results.

## Data Preparation

### Initial preparation in Excel

Before importing the data, I used Excel to review missing values, data formats and consistency across the datasets.

Missing values require particular care in this analysis: an absent record does not necessarily mean that no cases, deaths or vaccinations occurred.

### Import and validation

After importing the datasets into SQL Server, I inspected both tables to check that the records and columns were available for analysis.

```sql
SELECT *
FROM CovidDeaths
ORDER BY location, date;

SELECT *
FROM CovidVaccinations
ORDER BY location, date;
```

### Data type conversion

Some numerical fields were imported as text. I used explicit conversions to perform calculations on these fields.

For example, `total_deaths` and `total_cases` were converted to numerical values when calculating the reported case-fatality percentage. `NULLIF` can protect these calculations against division by zero.

## Analysis Approach

### 1. Explore UK cases and deaths

I selected daily UK records to examine the relationship between new cases, cumulative cases, cumulative deaths and population.

This provided the foundation for the UK analysis and helped distinguish daily additions from cumulative totals.

### 2. Calculate the reported case-fatality percentage

I calculated cumulative reported deaths as a percentage of cumulative reported cases:

**Reported case-fatality percentage = cumulative reported deaths ÷ cumulative reported cases × 100**

A version of this query restricted to the study period is:

```sql
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    100.0 * CAST(total_deaths AS FLOAT)
        / NULLIF(CAST(total_cases AS FLOAT), 0)
        AS ReportedCaseFatalityPercentage
FROM CovidDeaths
WHERE location = 'United Kingdom'
  AND date >= '2020-01-01'
  AND date < '2024-01-01'
ORDER BY date;
```

This is a descriptive ratio of reported figures. It does not measure an individual’s probability of dying after infection, because testing coverage, unrecorded infections and reporting delays affect the calculation.

### 3. Aggregate reported new cases and deaths

I used `SUM(new_cases)` and `SUM(new_deaths)` to calculate reported additions over selected periods.

This approach avoids repeatedly counting cumulative figures. For example, summing `total_cases` across daily records would overstate the number of cases.

The script includes a query specifically calculating reported new cases during 2023. Some other queries labelled “2023” have their date filters commented out and therefore need correction before being used as annual results.

### 4. Examine monthly variations during 2023

I grouped UK records by month to compare reported new cases and deaths throughout 2023.

```sql
SELECT
    MONTH(date) AS MonthNumber,
    DATENAME(MONTH, date) AS MonthName,
    location,
    SUM(new_cases) AS TotalNewCases,
    SUM(new_deaths) AS MonthlyDeaths
FROM CovidDeaths
WHERE location = 'United Kingdom'
  AND date >= '2023-01-01'
  AND date < '2024-01-01'
GROUP BY
    MONTH(date),
    DATENAME(MONTH, date),
    location
ORDER BY MonthNumber;
```

Monthly aggregation provides a clearer view of variation than individual daily records, although reporting changes and missing observations still need to be considered.

### 5. Compare reported cases relative to population

I calculated cumulative reported cases as a percentage of population and compared the highest recorded values across European countries.

**Cumulative reported cases relative to population = cumulative reported cases ÷ population × 100**

This supports comparisons between countries of different population sizes. However, it should not be labelled the “percentage of people infected”: reported cases may include reinfections and exclude undetected infections.

### 6. Compare cumulative reported deaths across Europe

I grouped records by country and used `MAX(total_deaths)` to identify the highest recorded cumulative death count for each European country in the dataset.

This compares absolute reported totals. A comparison of deaths per 100,000 people would provide additional context by accounting for population differences.

The maximum recorded cumulative total may also differ from the latest recorded total if historical figures were revised.

### 7. Join case and vaccination records

I joined the two tables using both `location` and `date` to align vaccination activity with the corresponding country and reporting day.

```sql
SELECT
    CD.location,
    CD.date,
    CD.population,
    CV.new_vaccinations
FROM CovidDeaths AS CD
INNER JOIN CovidVaccinations AS CV
    ON CD.location = CV.location
   AND CD.date = CV.date
WHERE CD.continent = 'Europe'
ORDER BY CD.location, CD.date;
```

This query retains records with matching country and date values in both tables. Before interpreting the output, each table should be checked for duplicate country-date combinations, as duplicates could inflate the joined results.

### 8. Calculate cumulative vaccination doses

I used a window function to calculate a running total of reported new vaccination doses for each country.

```sql
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER (
    PARTITION BY CD.location
    ORDER BY CD.date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS CumulativeReportedDoses
```

`PARTITION BY` restarts the calculation for each country, while `ORDER BY` accumulates the doses chronologically.

A CTE then made the running total available for a population-adjusted calculation:

**Cumulative reported doses per 100 people = cumulative reported doses ÷ population × 100**

This measures doses rather than unique people vaccinated. It can exceed 100 because individuals may receive multiple doses. Missing daily vaccination records can also make a running sum incomplete.

## SQL Views Created

I created six views to make selected outputs reusable.

| View | Purpose |
|---|---|
| `Monthly_deaths` | Monthly reported UK cases and deaths during 2023 |
| `deathpercentage` | Daily cumulative reported case-fatality percentage for the UK |
| `CovidDeaths_UK` | Aggregated reported new UK cases and deaths |
| `DeathCount_europe` | Highest recorded cumulative reported deaths by European country |
| `population_infected_percentage` | Highest recorded cumulative reported cases relative to population |
| `Total_new_cases` | Total reported new UK cases during 2023 |

For clearer interpretation, `population_infected_percentage` would be better named `ReportedCasesRelativeToPopulation`.

## Limitations

- **Reported cases are not all infections.** Testing availability and reporting practices affect the number recorded.
- **Missing values are not automatically zero.** Incomplete reporting can affect totals and comparisons.
- **Cumulative ratios have limitations.** Cases and subsequent deaths occur at different times.
- **Vaccination doses are not vaccinated people.** Dose totals cannot directly establish population vaccination coverage.
- **Country comparisons require context.** Population size, demographics and reporting practices may differ.
- **The analysis is descriptive.** These queries alone cannot establish the effects of vaccination, restrictions or other factors on cases and deaths.
- **Date filters need to be consistent.** Unrestricted queries and queries using `GETDATE()` do not define a fixed 2020–2023 study period.

## Findings and Project Status

The SQL script covers UK case and death exploration, monthly analysis for 2023, European comparisons and cumulative vaccination calculations.

Numerical findings are not included here because the query outputs have not been supplied. These results are needed before identifying peak months, ranking countries or describing changes in reported cases and deaths.

## Learning and Next Steps

This project demonstrates how SQL can turn daily public-health records into structured analytical outputs through aggregation, joins, CTEs, window functions and views.

It also highlights the importance of defining metrics accurately. Reported cases, unique people infected, vaccination doses and people vaccinated are different measures and should be labelled accordingly.

The next steps are to standardise the date filters, validate missing values and duplicate records, and use the verified outputs to build charts showing monthly UK cases and deaths, European population-adjusted comparisons and vaccination activity.




