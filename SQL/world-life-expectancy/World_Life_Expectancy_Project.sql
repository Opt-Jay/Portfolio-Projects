/*
INTRODUCTION:
This project explores the World Life Expectancy dataset using SQL to perform both data cleaning and 
exploratory data analysis (EDA). The aim is to prepare the dataset for reliable use, uncover patterns, 
and identify key factors that influence life expectancy across countries. The process begins with 
cleaning tasks such as removing duplicates, handling missing values, and standardizing fields 
to ensure data integrity. Once the dataset is structured and validated, EDA techniques are applied 
to summarize key characteristics, analyze trends over time, and examine relationships between life 
expectancy and other indicators such as GDP, Status (Developed/Developing), BMI, and Adult Mortality. 
By combining data preparation with analytical exploration, this project provides insights into global 
health trends while demonstrating the practical application of SQL for solving real-world problems.
*/
-- PHASE 1
-- DATA CLEANING PHASE
-- This section ensures the data is properly cleaned, structured, and ready for accurate analysis and use.

-- Connect to database(MySQL)
USE World_Life_Expectancy_Project;

-- Task 1: View the World_Life_Expectancy table
SELECT * FROM World_Life_Expectancy_Project;

-- Task 2: View number of rows
SELECT COUNT(*) FROM World_Life_Expectancy_Project;

-- Task 3: Querry to know whether or not there are duplicates
SELECT Country, Year, CONCAT(Country, Year) AS Country_Year, COUNT(CONCAT(Country, Year)) AS Frequency
FROM World_Life_Expectancy_Project
GROUP BY Country, Year, Country_Year
HAVING Frequency > 1
;

-- Task 4: Identify the row number of the field 'Country_Year' for partitioning
SELECT* 
FROM(
	SELECT Row_ID, CONCAT(Country, Year) AS Country_Year,
	ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num
	FROM World_Life_Expectancy_Project) AS Row_Table
WHERE Row_Num > 1
;

-- Task 5: Deleting the three rows identified by their Row_ID
DELETE FROM World_Life_Expectancy_Project
WHERE 
	Row_ID IN(
	SELECT Row_ID
	FROM(
		SELECT Row_ID, CONCAT(Country, Year) AS Country_Year,
		ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num
		FROM World_Life_Expectancy_Project) AS Row_Table
		WHERE Row_Num > 1)
;

-- Task 6: Querry task 3 again to know whether the duplicates still exist or are deleted
SELECT Country, Year, CONCAT(Country, Year) AS Country_Year, COUNT(CONCAT(Country, Year)) AS Frequency
FROM World_Life_Expectancy_Project
GROUP BY Country, Year, Country_Year
HAVING Frequency > 1
;

-- Task 7: Identify missing rows by Status
SELECT * 
FROM World_Life_Expectancy_Project
WHERE Status = ''
;

-- Task 8: Identifying distinct values in the Status field
SELECT DISTINCT Status
FROM World_Life_Expectancy_Project
WHERE Status <> ''
;

-- Task 9: Populate the blanks with Unique Status1 'Developing'
-- This is possible since the Status is within range and can be identified both from previous year and the year which follows
UPDATE World_Life_Expectancy_Project t1
JOIN World_Life_Expectancy_Project t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing'
;

-- Task 10: Populate the blanks with Unique Status2 'Developed'
UPDATE World_Life_Expectancy_Project t1
JOIN World_Life_Expectancy_Project t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed'
;

-- Task 11: Observe where the Life_expectancy is blank
SELECT* 
FROM World_Life_Expectancy_Project
WHERE Life_expectancy = ''
;

-- Task 12: Extract the outer years of the blank Life_expectancy and calculate the mean 
-- They have an upward trend which means we can find average between their two outer years and populate it
SELECT t1.Country, t1.Year, t1.Life_expectancy, 
t2.Country, t2.Year, t2.Life_expectancy, 
t3.Country, t3.Year, t3.Life_expectancy,
ROUND((t2.Life_expectancy + t3.Life_expectancy)/2,1)
FROM World_Life_Expectancy_Project t1
JOIN World_Life_Expectancy_Project t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year -1
JOIN World_Life_Expectancy_Project t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
WHERE t1.Life_expectancy = ''
;

-- Task 13: Update the blank Life_expectancy field (t1) by populating it with the mean filed (Average_Value)
UPDATE World_Life_Expectancy_Project t1
JOIN World_Life_Expectancy_Project t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year -1
JOIN World_Life_Expectancy_Project t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.Life_expectancy = ROUND((t2.Life_expectancy + t3.Life_expectancy)/2,1)
WHERE t1.Life_expectancy = ''
;


-- PHASE 2
/*
Exploratory Data Analysis (EDA)
In this phase, the data is examined to summarize its main characteristics and uncover meaningful patterns using key EDA 
techniques such as summary statistics, data distribution analysis, handling missing values, identifying unique values, 
time series exploration, and examining joins and relationships.

The EDA process is carried out in two stages:
	1.	In conjunction with data cleaning – running counts, groupings, and other checks to validate data quality.
	2.	Insight generation – identifying trends, patterns, and relationships that can inform future analysis and decision-making.
*/

-- Task 14: Identifying how each country has done in the past 17 years with their life expectancy
-- Finding the lowest and highest
SELECT Country, MIN(Life_expectancy), MAX(Life_expectancy)
FROM World_Life_Expectancy_Project
GROUP BY Country
HAVING MIN(Life_expectancy) <> 0
AND MAX(Life_expectancy) <> 0
ORDER BY Country DESC
;

-- Task 15: Identifying which countries have done well and which ones haven't
SELECT Country, 
MIN(Life_expectancy), 
MAX(Life_expectancy),
ROUND(MAX(Life_expectancy) - MIN(Life_expectancy), 1) AS Life_Increase_Over_15yrs
FROM World_Life_Expectancy_Project
GROUP BY Country
HAVING MIN(Life_expectancy) <> 0
AND MAX(Life_expectancy) <> 0
ORDER BY Life_Increase_Over_15yrs DESC
;

-- Task 16: Identifying the average life expectancy for each year
-- Again let's factor out those with zero's so that they do not affect the average calculation
SELECT Year, ROUND(AVG(Life_expectancy), 2)
FROM World_Life_Expectancy_Project
WHERE Life_expectancy <> 0
AND Life_expectancy <> 0
GROUP BY Year
ORDER BY Year DESC
;

-- Task 17: Identifying Correlations between Life Expectancy and Other Indicators
-- This task explores the relationship between Life Expectancy and key indicators, with a focus on GDP. 
-- Records with missing GDP values are filtered out to ensure accuracy before analyzing potential correlations.
SELECT Country, ROUND(AVG(Life_expectancy),1) AS Life_exp, ROUND(AVG(GDP),1) AS GDP
FROM World_Life_Expectancy_Project
GROUP BY Country
HAVING Life_exp > 0
AND GDP > 0
ORDER BY GDP ASC
;
-- we can observe that the GDP and life_exp are correlated. As GDP goes up, so is life expectancy 
-- the vice versa is seen below where we order by GDP DESC
-- At first glance it can be seen that it has a pretty positive correlation

SELECT Country, ROUND(AVG(Life_expectancy),1) AS Life_exp, ROUND(AVG(GDP),1) AS GDP
FROM World_Life_Expectancy_Project
GROUP BY Country
HAVING Life_exp > 0
AND GDP > 0
ORDER BY GDP DESC;

-- Task 18: Using a case statement to bucket or group data into top_GDP and Low_GDP with their average Life Expectancies
SELECT
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
ROUND(AVG(CASE WHEN GDP >= 1500 THEN Life_expectancy ELSE NULL END), 1) High_GDP_Life_expectancy,
SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) Low_GDP_Count,
ROUND(AVG(CASE WHEN GDP <= 1500 THEN Life_expectancy ELSE NULL END), 1) Low_GDP_Life_expectancy
FROM World_Life_Expectancy_Project
;

-- Task 19: Exploring the Status to determining the unique values in the Status field
SELECT Status
FROM World_Life_Expectancy_Project
GROUP BY Status
;

-- Task 20: Determining the average life expectancy for each Status group
SELECT Status, ROUND(AVG(Life_expectancy), 1) AS Average_Life_expectancy
FROM World_Life_Expectancy_Project
GROUP BY Status
;

-- Task 21: Identifying the number of countries in each group to determine fairness and avoid skewness
-- this is because only one country could be a Developed country
-- this means that the information could be a bit skewed in favour of Developed Countries 32 vs 161
SELECT Status, COUNT(DISTINCT Country) AS Number_of_Countries
FROM World_Life_Expectancy_Project
GROUP BY Status;

-- Task 22: Concat Task 20 & 21

SELECT 
	Status, 
	COUNT(DISTINCT Country) AS Number_of_Countries, 
	ROUND(AVG(Life_expectancy), 1) AS Average_Life_expectancy
FROM World_Life_Expectancy_Project
GROUP BY Status;


-- Task 23: Exploring Countries and their BMI; whether or not there is some sort of correlation
SELECT 
	Country, 
    ROUND(AVG(Life_expectancy),1) AS Life_exp, 
    ROUND(AVG(BMI),1) AS BMI
FROM World_Life_Expectancy_Project
GROUP BY Country
HAVING Life_exp > 0
AND BMI > 0
ORDER BY BMI ASC;

-- Task 24: Exploring the Adult Mortality
-- Using the rolling total method to know how the adult mortality for each country have accumulated over time
SELECT 
	Country,
    Year,
    Life_expectancy,
    Adult_Mortality,
    SUM(Adult_Mortality) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM World_Life_Expectancy_Project;

/*
CONCLUSION & RECOMMENDATIONS
Conclusion:
This project successfully demonstrated how to clean, structure, and analyze a large dataset to uncover meaningful 
insights about global life expectancy trends. The cleaning phase ensured data integrity by removing duplicates, 
addressing missing values, and standardizing fields, which provided a solid foundation for reliable analysis. 
The exploratory phase revealed key patterns:
•	Economic factors matter. Countries with higher GDP generally show higher life expectancy, confirming a positive 
	correlation between wealth and health outcomes.
•	Status differentiation. Developed countries exhibit consistently higher life expectancy than developing countries, 
	though the majority of nations still fall into the developing category, highlighting global health disparities.
•	Other health indicators. BMI and Adult Mortality rates also influence life expectancy, reinforcing the 
	importance of holistic health and lifestyle measures beyond economic strength.

Recommendations:
1.	Policy focus on developing nations – Global health initiatives should prioritize developing countries, where 
	improvements in economic conditions and healthcare infrastructure can drive significant gains in life expectancy.
2.	Holistic interventions – Beyond economic growth, efforts should address nutrition (BMI), preventative care, 
	and reduction in adult mortality through early detection and better health services.
3.	Future analysis – Further studies could integrate additional datasets (e.g., education levels, 
healthcare expenditure, environmental indicators) to build a more comprehensive understanding of the drivers of 
life expectancy.

Overall, this project highlights the value of SQL for end-to-end data analysis—from cleaning and structuring to 
exploring correlations and generating actionable insights for decision-making.
*/



