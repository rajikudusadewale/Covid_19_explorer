select * from CovidDeaths
order by 3,4

--select * from CovidVaccinations
--order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2


-- looking at the total cases vs total deaths
-- ensuring the two columns are here numeric datatype we convert
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM CovidDeaths
ORDER BY 1, 2

-- checking for only United kingdom
-- this shows the likelihood of dying if you contract Covid in United Kingdom
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM CovidDeaths
where location like '%Kingdom%'
ORDER BY 1, 2


-- Total Cases vs Population
-- to know the percentage of population that got Covid in the UK
SELECT location, date, population, total_cases,
(CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS InfectedPopulationPercentage
FROM CovidDeaths
--where location like '%Kingdom%'
ORDER BY 1, 2

--looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, 
MAX((CAST(total_cases AS FLOAT)/CAST(population AS FLOAT)))*100 AS TopCountriesInfectedByPopulation
FROM CovidDeaths
Group by location, population
ORDER BY TopCountriesInfectedByPopulation desc

--Cyprus has the highest infection rate compared to their population


-- Countries with highest death counts per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCounts
FROM CovidDeaths
Group by location
ORDER BY TotalDeathCounts desc
-- we notice, continent is showing in the country column, need to remove that. 

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCounts
FROM CovidDeaths
where continent is not null 
Group by location
ORDER BY TotalDeathCounts desc
-- USA has the highest death count 

-- let's break death count into continent
-- showing continent with highest death counts per population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCounts
FROM CovidDeaths
where continent is not null 
Group by continent
ORDER BY TotalDeathCounts desc


-- Global Numbers, using data to know the sum of cases and deaths


SELECT date, 
       SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS INT)) AS total_deaths, 
       CASE WHEN SUM(new_cases) = 0 THEN NULL ELSE 
            SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 
       END AS DeathPercentage 
FROM CovidDeaths 
WHERE continent IS NOT NULL 
GROUP BY date 
ORDER BY date, total_cases

-- showing global total cases, total deaths, and death percentage
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from CovidDeaths
where continent is not null
order by 1,2


-- Checking on Covid vaccination table
--this joined the two table together

select * from CovidVaccinations
join CovidDeaths
on CovidDeaths.location = CovidVaccinations.location
and CovidDeaths.date = CovidVaccinations.date

-- looking at total population vs vaccination
select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date ,CovidDeaths.population, CovidVaccinations.new_vaccinations
from CovidVaccinations
join CovidDeaths
on CovidDeaths.location = CovidVaccinations.location
and CovidDeaths.date = CovidVaccinations.date
where CovidDeaths.continent is not null 
order by 2,3



select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date ,CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(cast(CovidVaccinations.new_vaccinations as int)) 
over (Partition by CovidDeaths.location order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from CovidVaccinations
join CovidDeaths
on CovidDeaths.location = CovidVaccinations.location
and CovidDeaths.date = CovidVaccinations.date
where CovidDeaths.continent is not null 
order by 2,3


-- using CTE (common table expression)
with PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date ,CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(cast(CovidVaccinations.new_vaccinations as bigint)) 
over (Partition by CovidDeaths.location order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from CovidVaccinations
join CovidDeaths
on CovidDeaths.location = CovidVaccinations.location
and CovidDeaths.date = CovidVaccinations.date
where CovidDeaths.continent is not null 
--order by 2,3
)
select *
from PopvsVac

---
with PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date ,CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(cast(CovidVaccinations.new_vaccinations as bigint)) 
over (Partition by CovidDeaths.location order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
from CovidVaccinations
join CovidDeaths
on CovidDeaths.location = CovidVaccinations.location
and CovidDeaths.date = CovidVaccinations.date
where CovidDeaths.continent is not null 
--order by 2,3
)
select *, 
       (cast(RollingPeopleVaccinated as bigint)/nullif(population, 0))*100 as VaccinationPercentage
from PopvsVac


------------------------------------------------------
-- Temp table
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date ,CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(cast(CovidVaccinations.new_vaccinations as bigint)) 
over (Partition by CovidDeaths.location order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from CovidVaccinations
join CovidDeaths
on CovidDeaths.location = CovidVaccinations.location
and CovidDeaths.date = CovidVaccinations.date
--where CovidDeaths.continent is not null 

select *, (RollingPeopleVaccinated/Population)*100 as PopRollingPeopleVaccinated
from #PercentPopulationVaccinated


--- Creating View to store data for later visualization
create View PercentPopulationVaccinated as
select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date ,CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(cast(CovidVaccinations.new_vaccinations as bigint)) 
over (Partition by CovidDeaths.location order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from CovidVaccinations
join CovidDeaths
on CovidDeaths.location = CovidVaccinations.location
and CovidDeaths.date = CovidVaccinations.date
where CovidDeaths.continent is not null 



-- Work view/table
select * from PercentPopulationVaccinated