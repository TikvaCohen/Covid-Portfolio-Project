SELECT *
FROM [Portfolio Project].dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 3,4


--Select *
--FROM [Portfolio Project].dbo.CovidVaccinations$
--ORDER BY 3,4

--Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project].dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project].dbo.CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


--Looking at Total Cases vs Population
--Shows what percentage of population was infected with Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM [Portfolio Project].dbo.CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS 
	PercentPopulationInfected
FROM [Portfolio Project].dbo.CovidDeaths$
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project].dbo.CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

--Let's Break Things Down By Continent


--Showing the Continents with the Highest Death Count

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM [Portfolio Project].dbo.CovidDeaths$
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc

--Global Numbers

SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM [Portfolio Project].dbo.CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


--Looking at Total Population vs Vaccinations
--Shows Percentage of Population that has received at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project].dbo.CovidDeaths$ dea
--,(RollingPeopleVaccinated/population)*100
Join [Portfolio Project].dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


--Use CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project].dbo.CovidDeaths$ dea
Join [Portfolio Project].dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


--TEMP Table

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project].dbo.CovidDeaths$ dea
Join [Portfolio Project].dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null


SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


--Creating View to Store Data for Later Visualizations

CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project].dbo.CovidDeaths$ dea
Join [Portfolio Project].dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated