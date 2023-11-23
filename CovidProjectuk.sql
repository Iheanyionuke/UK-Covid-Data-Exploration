/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
---Checking my data if they are properly imported----
select *
from CovidDeaths
order by 3,4;

select*
from CovidVaccinations
order by 3,4;

---Select data im going to be using for 

Select location,date,new_cases,total_cases,total_deaths,population
from CovidDeaths
order by 1,2;

------Getting the deathrate for United Kingdom 
----I Had to use cast because  i tried to perform a division operation on data of type nvarchar, which is not allowed.

Select location,date,total_cases,total_deaths,cast(total_deaths as float)/cast(total_cases as float)*100 AS Deathpercentage
from CovidDeaths
where location like '%kingdom%' and cast(total_deaths as float)/cast(total_cases as float)*100  is not null
order by 3,4;

---Getting the deathrate for United Kingdom  2023
Select location,date,total_cases,total_deaths,new_cases, cast(total_deaths as float)/cast(total_cases as float)*100 AS Deathpercentage
from CovidDeaths
where location like '%kingdom%'
AND date >= '2023-01-01' 
AND date <= GETDATE() ;
--order by 1,2 desc


----deathrate for United Kingdom from inception of covid
Select location,date,total_cases,total_deaths,new_cases, cast(total_deaths as float)/cast(total_cases as float)*100 AS Deathpercentage
from CovidDeaths
where 
location like '%kingdom%';


---Getting the deathpercentage for United Kingdom in the 2023
Select location,date,population,cast(total_deaths as float)/cast(total_cases as float)*100 AS Deathpercentage
from CovidDeaths
where location like '%kingdom%';---AND date >= '2023-01-01' AND date <= getdate() 

	---- People who have died from Covid in the 2023 in the uk

SELECT
    location,population,sum(new_cases)AS Totalcases, sum(new_deaths) AS totalnewdeaths
	from CovidDeaths
	WHERE location LIKE '%kingdom%'
	----and year(date)= 2023
	group by location,population;

	

	---total covid cases in united kingdom 2023

	SELECT
    location,population, sum(new_cases)AS Totalnewcases
FROM 
	CovidDeaths
	WHERE location LIKE '%kingdom%'
	and year(date)=2023
	--AND date <= GETDATE()
	GROUP BY
    location,population;

	----Percentage of polpulation that got covid
 Select location,date,total_cases,population,total_cases / population*100 AS Populationpercentage
from CovidDeaths
where
	location like '%kingdom%';---AND date >= '2023-01-01' AND date <= getdate() 

	----max Percentage of polpulation that got covid in europe
 Select location AS Country,max(cast(total_cases as int)) AS Highestinfectioncount,population,max((total_cases / population)*100) AS Populationpercentage
from CovidDeaths
where
	continent like '%europe%'   
	group by location,population
		having max((total_cases / population)*100)  is not null
	order by 2 desc;

	 Select location AS Country,max(cast(total_deaths as int)) AS deathcount,max(new_deaths)--population,max((total_cases / population)*100) AS Populationpercentage
from CovidDeaths
where
	continent like '%europe%'   
	group by location,population
		--having max((total_cases / population)*100)  is not null
	order by 2 desc;

----	Month by month cases as against new deaths----
Select
    MONTH(date) AS Month,location,
    SUM(new_cases) AS total_new_cases, sum(new_deaths) AS monthly_deaths
FROM
    CovidDeaths
WHERE location LIKE '%kingdom%'
    AND YEAR(date) = 2023 -- Specify the desired year
GROUP BY
    MONTH(date),location
ORDER BY 1;


-------total death count in europe
select location, max(cast(total_deaths as int)) AS totaldeathcount
from CovidDeaths
where 
	continent like '%europe%'   
group by location
order by totaldeathcount desc;

---using joins to get population in eroupe that was vaccinated daily.

select CD.location,CD.date,CD.population, CV.new_vaccinations
FROM CovidDeaths CD
JOIN CovidVaccinations CV
ON CD.location = CV.location
AND CD.date =CV.date
WHERE 
CD.continent like '%europe%'
AND CD.continent IS NOT NULL
ORDER BY 1,2,4;

---Using partition by with a window function we get the sum of new vaccination daliy as a rolling number 

select CD.location,CD.date,CD.population, CV.new_vaccinations,
sum(cast(cv.new_vaccinations as int)) over( partition by CD.location order by cd.location,cd.date) AS roll_new_vaccination
FROM CovidDeaths CD
JOIN CovidVaccinations CV
ON CD.location = CV.location
AND CD.date = CV.date
WHERE 
CD.continent like '%europe%'
--AND CD.continent IS NOT NULL
ORDER BY 1,2,4;


----getting the percentage of people vaccinated daily in europe ,I used CTE Fuction for the query

with popvsvac (location,date,population,new_vaccinations,roll_new_vaccination)
as
(
select CD.location,CD.date,CD.population, CV.new_vaccinations,
sum(cast(cv.new_vaccinations as int)) over( partition by CD.location order by cd.location,cd.date) AS roll_new_vaccination
FROM CovidDeaths CD
JOIN CovidVaccinations CV
ON CD.location = CV.location
AND CD.date = CV.date
WHERE 
CD.continent like '%europe%'
--and new_vaccinations is not null
--AND CD.continent IS NOT NULL
--ORDER BY 1,2,4
)
select *,(roll_new_vaccination/population)*100
from popvsvac;


-----creating views for data viualizations
--table 1
create view Monthly_deaths as
Select
    MONTH(date) AS Month,location,
    SUM(new_cases) AS total_new_cases, sum(new_deaths) AS monthly_deaths
FROM
    CovidDeaths
WHERE location LIKE '%kingdom%'
    AND YEAR(date) = 2023 -- Specify the desired year
GROUP BY
    MONTH(date),location
--ORDER BY 1;

--Table 2
create view deathpercentage as
Select location,date,total_cases,total_deaths,cast(total_deaths as float)/cast(total_cases as float)*100 AS Deathpercentage
from CovidDeaths
where location like '%kingdom%' and cast(total_deaths as float)/cast(total_cases as float)*100  is not null


---TABLE 3
create view CovidDeaths_UK As
SELECT
    location,population,sum(new_cases)AS Totalcases, sum(new_deaths) AS totalnewdeaths
	from CovidDeaths
	WHERE location LIKE '%kingdom%'
	--and year(date)= 2023
	group by location,population;


	---table 4
-------total death count in europe

Create view DeathCount_europe as
select location, max(cast(total_deaths as int)) AS totaldeathcount
from CovidDeaths
where 
	continent like '%europe%'   
group by location
----order by totaldeathcount desc;


---table 5
create view population_infected_percentage as
 Select location AS Country,max(cast(total_cases as int)) AS Highestinfectioncount,population,max((total_cases / population)*100) AS Populationpercentage
from CovidDeaths
where
	continent like '%europe%'   
	group by location,population
		having max((total_cases / population)*100)  is not null
	--order by 2 desc;

	----table 6
		---new cases 2023
create view Total_new_cases as
		SELECT
    location,population, sum(new_cases)AS Totalnewcases
FROM 
	CovidDeaths
	WHERE location LIKE '%kingdom%'
	and year(date)=2023
	--AND date <= GETDATE()
	GROUP BY
    location,population;
