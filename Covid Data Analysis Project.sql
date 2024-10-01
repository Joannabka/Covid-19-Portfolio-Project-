# Covid-19 Pandemic Project (Practice Project)-
# Skills: SQL Calculations, CTEs (Common Table Expression), Temp tables, Aggregate Functions, Creating Views, Convertig Data Types 
# Discuss each query and findings 

Select *
FROM potfolioproject.coviddeaths
Where continent is not null
order by 3,4;
# Returned all 81060 rows of data in Covid Deaths Table 

# Select Relevant Data 
Select location, date, total_cases, new_cases, total_deaths, population
FROM potfolioproject.coviddeaths
Where continent is not null
order by 1,2;


# Exploring total cases vs population 
# Shows what percentage of the population infected with Covid
Select location, date, population, total_cases, (total_cases/population)*100 as PercentagePopulationInfected
FROM potfolioproject.coviddeaths
Where location like '%United Kingdom%'
order by 1,2;
# the highest recordered percentage of the population infected with Covid in the UK was 6.53% as of 30/04/2021. Which is 6.5 times the % just over 4months earlier (15/10/2020)

# Highest Infection Rate compared to Population 
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) PercentagePopulationInfected 
FROM potfolioproject.coviddeaths
Where location like '%United Kingdom%'
Group by location, population
order by PercentagePopulationInfected desc;
# Highest Infection Rate compared to Population was 4432246 cases out of 67886004 (6.53%)

# first five countries with highest death count per population
Select location, MAX(CAST(Total_Deaths as signed)) as TotalDeathCount
FROM potfolioproject.coviddeaths
where continent is not null 
Group by Location
order by TotalDeathCount desc;
# highest recorded death count was 576232 in the united states; Brazil had 403781; Mexico had the 216907; India had 211853; and the Uk had 127775

# BREAKING THINGS DOWN BY CONTINENT
# the highest death count per population by continent 
Select location, MAX(cast(Total_deaths as signed)) as TotalDeathCount
From potfolioProject.CovidDeaths
Where continent is null 
Group by location
order by TotalDeathCount desc;
# Europe-1016750; North America-847942; European Union-688896; South America-672415; Africa-121784; Oceania-1046; International-15

# Same as above for visualisation purposes 
Select continent, MAX(cast(Total_deaths as signed)) as TotalDeathCount
From potfolioProject.CovidDeaths
Where continent is not null 
Group by continent 
order by TotalDeathCount desc;

# GLOBAL NUMBERS
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as signed)) as total_deaths, SUM(cast(new_deaths as signed))/SUM(New_Cases)*100 as DeathPercentage
From potfolioProject.covidDeaths
Where continent is not null 
Group By date
order by 1,2;
# When cases where first getting recorded there were 98 total cases and 1 death; 1% of covid cases resulted in death as of 23/01/2020. The highest % of recorded death globally was 28.37% as of 24/02/2020.

#Total cases across the world 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as signed)) as total_deaths, SUM(cast(new_deaths as signed))/SUM(New_Cases)*100 as DeathPercentage
From potfolioProject.covidDeaths
Where continent is not null 
order by 1,2;
# total cases of 150574977 globally, 2.11% death toll globally

# Total Population vs Vaccinations
# Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations,
       SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS SIGNED)) 
           OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated,
       (SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS SIGNED)) 
           OVER (PARTITION BY dea.location ORDER BY dea.date) / dea.population) * 100 AS VaccinationPercentage
FROM potfolioproject.covidDeaths dea
JOIN potfolioproject.covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;
# Gibraltar had the largest % Population that has recieved at least one Covid Vaccine, 182.12%

# Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT dea.continent, 
           dea.location, 
           dea.date, 
           dea.population, 
           vac.new_vaccinations,
           SUM(COALESCE(CAST(vac.new_vaccinations AS SIGNED), 0)) 
               OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM potfolioproject.coviddeaths dea
    JOIN potfolioproject.covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, 
       (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM PopvsVac
ORDER BY Location, Date;
# When filtered to just the UK, the highest percentage of population vaccinated was 60.16% as of 27/10/2020


# Using Temp Table to perform Calculation on Partition By in previous query
# Drop the temporary table if it already exists
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

# Create the temporary table
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS SIGNED)) 
           OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

# Select from the temporary table and calculate the percentage
SELECT *, 
       (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;




-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations,
       SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS SIGNED)) 
           OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated,
       (SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS SIGNED)) 
           OVER (PARTITION BY dea.location ORDER BY dea.date) / dea.population) * 100 AS PercentPopulationVaccinated
FROM potfolioproject.coviddeaths dea
JOIN potfolioproject.covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



