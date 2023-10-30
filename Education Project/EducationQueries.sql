SELECT *
FROM EducationProject..EducationByCounty
;

SELECT *
FROM EducationProject..DistrictFinances
;


--Show percentage of population without a high school diploma & with bachelors degree, grouped by state
SELECT
	State,
	SUM(NoHsDiploma)/SUM(Population)*100 AS PercNoHsDiploma,
	SUM(BachelorsOrHigher)/SUM(Population)*100 AS PercBachelorsOrHigher
FROM EducationProject..EducationByCounty edu
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
GROUP BY State
ORDER BY PercNoHsDiploma DESC
;


--County in each state with the lowest percentage without a high school diploma.
--Use PARTITION BY to display statewide average percent and CTE to query with this value.
WITH MinPercent AS
(SELECT
State, CountyName, PercentNoHsDiploma AS MinPercNoHsDiploma, AVG(PercentNoHsDiploma) OVER (PARTITION BY State) AS StateAverage
FROM EducationProject..EducationByCounty edu
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
)
SELECT State, CountyName, MinPercNoHsDiploma, StateAverage
FROM MinPercent
WHERE
	MinPercNoHsDiploma IN (SELECT MIN(MinPercNoHsDiploma) FROM MinPercent GROUP BY State)
ORDER BY MinPercNoHsDiploma
;


--County in each state with the highest percentage without a high school diploma.
--Use PARTITION BY to display statewide average percent and CTE to query on this value.
WITH MaxPercent AS
(SELECT
State, CountyName, PercentNoHsDiploma AS MaxPercNoHsDiploma, AVG(PercentNoHsDiploma) OVER (PARTITION BY State) AS StateAverage
FROM EducationProject..EducationByCounty edu
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
)
SELECT State, CountyName, MaxPercNoHsDiploma, StateAverage
FROM MaxPercent
WHERE
	MaxPercNoHsDiploma IN (SELECT MAX(MaxPercNoHsDiploma) FROM MaxPercent GROUP BY State)
ORDER BY MaxPercNoHsDiploma
;


--Spread between highest and lowest percentage without a high school diploma for each state. Use CTE to query based on aggregate columns.
WITH MinMaxSpread AS
(SELECT State,
	MIN(PercentNoHsDiploma) AS MinPercent,
	MAX(PercentNoHsDiploma) AS MaxPercent
FROM EducationProject..EducationByCounty
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
GROUP BY State
)
SELECT State, MinPercent, MaxPercent, MaxPercent - MinPercent AS SpreadPercent
FROM MinMaxSpread
ORDER BY SpreadPercent
;


--Create a temporary table aggregating finance data by county
DROP TABLE IF EXISTS #CountyFinance
CREATE TABLE #CountyFinance (
CountyCode varchar(50),
FallEnrollment int,
TotalRevenueThousands int,
FederalRevenueThousands int,
StateRevenueThousands int,
LocalRevenueThousands int,
TotalExpenditureThousands int,
TotalSpendingThousands int,
InstructionSpendingThousands int,
ServiceSpendingThousands int,
OtherSpendingThousands int
)
INSERT INTO #CountyFinance (
	CountyCode,
	FallEnrollment,
	TotalRevenueThousands,
	FederalRevenueThousands,
	StateRevenueThousands,
	LocalRevenueThousands,
	TotalExpenditureThousands,
	TotalSpendingThousands,
	InstructionSpendingThousands,
	ServiceSpendingThousands,
	OtherSpendingThousands
)
SELECT CountyCode,
	SUM(FallEnrollment) AS FallEnrollment,
	SUM(TotalRevenueThousands) AS TotalRevenueThousands,
	SUM(FederalRevenueThousands) AS FederalRevenueThousands,
	SUM(StateRevenueThousands) AS StateRevenueThousands,
	SUM(LocalRevenueThousands) AS LocalRevenueThousands,
	SUM(TotalExpenditureThousands) AS TotalExpenditureThousands,
	SUM(TotalSpendingThousands) AS TotalSpendingThousands,
	SUM(InstructionSpendingThousands) AS InstructionSpendingThousands,
	SUM(ServiceSpendingThousands) AS ServiceSpendingThousands,
	SUM(OtherSpendingThousands) AS OtherSpendingThousands
FROM EducationProject..DistrictFinances
WHERE FallEnrollment <> 0
GROUP BY CountyCode
ORDER BY CountyCode
;


--County in each state with the lowest revenue
--Use PARTITION BY to display statewide average revenue and CTE to query on this value.
WITH MinRevenue AS
(SELECT
State, CountyName, TotalRevenueThousands AS MinRevenueThousands, AVG(TotalRevenueThousands) OVER (PARTITION BY State) AS StateAverage
FROM #CountyFinance fin
INNER JOIN EducationProject..EducationByCounty edu
	ON edu.CountyCode = fin.CountyCode
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
)
SELECT State, CountyName, MinRevenueThousands, StateAverage
FROM MinRevenue
WHERE
	MinRevenueThousands IN (SELECT MIN(MinRevenueThousands) FROM MinRevenue GROUP BY State)
ORDER BY MinRevenueThousands
;


--County in each state with the highest revenue
--Use PARTITION BY to display statewide average revenue and CTE to query on this value.
WITH MaxRevenue AS
(SELECT
State, CountyName, TotalRevenueThousands AS MaxRevenueThousands, AVG(TotalRevenueThousands) OVER (PARTITION BY State) AS StateAverage
FROM #CountyFinance fin
INNER JOIN EducationProject..EducationByCounty edu
	ON edu.CountyCode = fin.CountyCode
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
)
SELECT State, CountyName, MaxRevenueThousands, StateAverage
FROM MaxRevenue
WHERE
	MaxRevenueThousands IN (SELECT MAX(MaxRevenueThousands) FROM MaxRevenue GROUP BY State)
ORDER BY MaxRevenueThousands
;


--Spread between highest and lowest revenue by state
WITH SpreadRevenue AS
(SELECT
	State,
	MIN(TotalRevenueThousands) AS MinRevenueThousands,
	MAX(TotalRevenueThousands) AS MaxRevenueThousands
FROM #CountyFinance fin
INNER JOIN EducationProject..EducationByCounty edu
	ON edu.CountyCode = fin.CountyCode
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
GROUP BY State
)
SELECT
	State, MinRevenueThousands, MaxRevenueThousands, MaxRevenueThousands - MinRevenueThousands AS SpreadRevenueThousands
FROM SpreadRevenue
ORDER BY SpreadRevenueThousands
;


--Join education data and finance data
SELECT *
FROM EducationProject..EducationByCounty edu
INNER JOIN #CountyFinance fin
	ON edu.CountyCode = fin.CountyCode
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
ORDER BY edu.CountyCode
;


--County data including progressive levels of education
SELECT State, CountyName,
(HsDiplomaOnly + SomeCollege + BachelorsOrHigher)/(Population*1.0) AS PercHsDiploma,
(SomeCollege + BachelorsOrHigher)/(Population*1.0) AS PercSomeCollege,
(BachelorsOrHigher)/(Population*1.0) AS PercBachelors,
TotalRevenueThousands/(FallEnrollment*1.0)*1000 AS RevenuePerStudent,
TotalSpendingThousands/(FallEnrollment*1.0)*1000 AS SpendingPerStudent
FROM EducationProject..EducationByCounty edu
INNER JOIN #CountyFinance fin
	ON edu.CountyCode = fin.CountyCode
;


--Aggregate data by RUCC code
SELECT RUCC,
	SUM(HsDiplomaOnly + SomeCollege + BachelorsOrHigher)/(SUM(Population)*1.0)*100 AS PercHsDiploma,
	SUM(SomeCollege + BachelorsOrHigher)/(SUM(Population)*1.0)*100 AS PercCollege,
	SUM(BachelorsOrHigher)/(SUM(Population)*1.0)*100 AS PercBachelors,
	SUM(TotalRevenueThousands)/(SUM(FallEnrollment)*1.0)*1000 AS RevenuePerStudent,
	SUM(TotalSpendingThousands)/(SUM(FallEnrollment)*1.0)*1000 AS SpendingPerStudent
FROM EducationProject..EducationByCounty edu
INNER JOIN #CountyFinance fin
	ON edu.CountyCode = fin.CountyCode
WHERE
	RUCC IS NOT NULL AND
	NoHsDiploma IS NOT NULL AND
	HsDiplomaOnly IS NOT NULL AND
	SomeCollege IS NOT NULL AND
	BachelorsOrHigher IS NOT NULL
GROUP BY RUCC
ORDER BY RUCC
;