-- Task 1 Cleaning our data Updating employee data

SELECT * FROM employee;

-- 1- Adding email adresses to employsee table

SELECT 
	REPLACE(employee_name, ' ', '.') AS New_name -- Replace the space with a full stop
FROM 
	employee;
    
-- Make it all lower case
SELECT 
	LOWER(REPLACE(employee_name, ' ', '.')) AS New_name 
FROM 
	employee;
    
-- use CONCAT() to add the rest of the email address:
SELECT 
	CONCAT(
		LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS New_email -- put all together  
FROM 
	employee;

-- Updating the table with the emails

UPDATE 
	employee
SET
	email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov');
    
 SET SQL_SAFE_UPDATES = 0;   

-- Check the update
SELECT * FROM employee;

-- 2- Cleaning phone number column
-- The phone numbers should be 12 characters long, consisting of the plus sign, area code (99), and the phone number digits 
SELECT 
	LENGTH(phone_number)
FROM
	employee;
-- it returns 13 that means there is an extra char
/* there is a space at the end of the number! 
If we try to send an automated SMS to that number it will fail
so we will use the TRIM function to remove ang extra spaces */

SELECT
	LENGTH(TRIM(phone_number))
FROM 
	employee;

-- Updating the column with the new values
UPDATE
	employee
SET 
	phone_number = TRIM(phone_number);
    
-- Check the update
SELECT
	LENGTH(phone_number)
FROM
	employee;
    
-- Task 2 Honouring the workers
-- count how many of our employees live in each town

SELECT
	town_name, 
    COUNT(employee_name) AS number_of_employees
FROM 
	employee
GROUP BY
	town_name;

-- top 3 field surveyors

SELECT 
	SUM(visit_count) As number_of_visits,
    assigned_employee_id
FROM
	visits
GROUP BY 
	assigned_employee_id
ORDER BY 
	SUM(visit_count) DESC
LIMIT 3;	
-- the top 3 employees IDS are 1, 30, 34
-- retrieve the info of this employees 
SELECT
	employee_name,
    phone_number,
    email,
    assigned_employee_id
FROM
	employee
WHERE
	assigned_employee_id IN (1, 30, 34);

-- Task 3 Analysing locatons
-- understand where the water sources are in Maji Ndogo
-- Create a query that counts the number of records per town
SELECT
	COUNT(*) AS records_per_town, 
    town_name
FROM 
	location
GROUP BY
	town_name;
/* From this table, 
 it's pretty clear that most of the water sources in the survey are situated
 in small rural communities, scattered across Maji Ndogo*/
    
-- count the records per province

SELECT
	COUNT(*) AS records_per_province, 
    province_name
FROM 
	location
GROUP BY
	province_name;
-- most of provinces have a similar number of sources, so every province is well-represented in the survey

/* 1. Create a result set showing:
• province_name
• town_name
• An aggregated count of records for each town (consider naming this records_per_town).
• Ensure your data is grouped by both province_name and town_name.
2. Order your results primarily by province_name. 
Within each province, further sort the towns by their record counts in descending order.*/

SELECT
	province_name,
    town_name,
    COUNT(town_name) AS records_per_town
FROM 
	location
GROUP BY 
	province_name,
    town_name
ORDER BY 
	province_name,
    COUNT(town_name) DESC;

-- These results show us that our field surveyors did an excellent job of documenting the status of our country's water crisis. 
-- Every province and town has many documented sources.

-- look at the number of records for each location type
SELECT
	location_type,
    COUNT(location_type) AS records_per_location_type
FROM
	location
GROUP BY
	location_type;
    
-- it looks like there are more rural sources than urban, but it's really hard to understand those numbers
-- Let's convert it to percentage
SELECT 23740/(23740+15910)*100 As percent_rural;    

-- We can see that 60% of all water sources in the data set are in rural communities

/*
insights gained from the location table:
1. Our entire country was properly canvassed, and our dataset represents the situation on the ground.
2. 60% of our water sources are in rural communities across Maji Ndogo.
We need to keep this in mind when we make decisions.
*/

-- Task 4 Diving into the sources
-- Discovering the water source table

SELECT * FROM water_source;

-- 1. How many people did we survey in total?
SELECT
	SUM(number_of_people_served) AS People_surveyed
FROM 
	water_source;
-- Note the total poeple rurveyed = 27628140

-- 2. How many wells, taps and rivers are there?
SELECT
	type_of_water_source,
    COUNT(type_of_water_source) AS Total_number
FROM
	water_source
WHERE
	type_of_water_source LIKE '%tap%' 
OR
	type_of_water_source LIKE '%river%'
OR 
	type_of_water_source LIKE '%well%'
GROUP BY 
	type_of_water_source;
-- We found that wells are the most popular water source 

-- 3. How many people share particular types of water sources on average?

SELECT 
	type_of_water_source,
    ROUND(AVG(number_of_people_served),0) AS Avg_number_of_people
FROM
	water_source
GROUP BY
	type_of_water_source;
/* 
Note tap_in_home = 644
The surveyors combined the data of many
households together and added this as a single tap record, 
but each household actually has its own tap. In addition to this, 
there is an average of 6 people living in a home. So 6 people actually share 1 tap (not 644) 
This means that 1 tap_in_home actually represents 644 / 6 = + or - 100 taps
*/
 -- 4. How many people are getting water from each type of source?   
SELECT 
	type_of_water_source,
    SUM(number_of_people_served) AS people_served_source
FROM
	water_source
GROUP BY
	type_of_water_source
ORDER BY 
	SUM(number_of_people_served) DESC;
    
SELECT 
	type_of_water_source,
    ROUND(SUM(number_of_people_served)/ 27628140 *100,0) AS percent_people_per_source
FROM
	water_source
GROUP BY
	type_of_water_source
ORDER BY 
	SUM(number_of_people_served) DESC;
    
-- Task 5 Start of a solution
/*
we will have to fix or improve all of the infrastructure, 
so we should start thinking about how we can make a data-driven decision
how to do it. I think a simple approach is to fix the things that affect most people first.
*/
-- a query that ranks each type of source based on how many people in total use it
-- A rank based on the total people served, grouped by the types -- A little harder.
    
SELECT 
	type_of_water_source,
    SUM(number_of_people_served) AS people_served,
    RANK() OVER ( ORDER BY SUM(number_of_people_served) DESC) AS Rank_population
FROM
	water_source
WHERE 
	type_of_water_source <> "tap_in_home"
GROUP BY
	type_of_water_source
ORDER BY 
	SUM(number_of_people_served) DESC;
-- Note: Don't use partition by with rank in this query otherwise the result will be the same in all rows = 1
-- our conclution from the previous query is that we should fix shared taps first, then wells.
/*
 The next question is, which shared taps or wells should be fixed first?
 We can use the same logic; the most used sources should really be fixed first.
*/

/*
Our requirements in the next uery
1. The sources within each type should be assigned a rank.
2. Limit the results to only improvable sources.
3. Think about how to partition, filter and order the results set.
4. Order the results to see the top of the list.
*/

SELECT 
	source_id,
	type_of_water_source,
    number_of_people_served,
    RANK() OVER ( PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC ) AS Priority_Rank
FROM
	 water_source
WHERE 
	type_of_water_source <> "tap_in_home"
GROUP BY
	source_id
ORDER BY 
	number_of_people_served DESC;


SELECT 
	source_id,
	type_of_water_source,
    number_of_people_served,
    DENSE_RANK() OVER ( PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC ) AS Priority_DENSE_Rank
FROM
	water_source
WHERE 
	type_of_water_source <> "tap_in_home"
GROUP BY
	source_id
ORDER BY 
	number_of_people_served DESC;


SELECT 
	source_id,
	type_of_water_source,
    number_of_people_served,
	ROW_NUMBER() OVER ( PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC ) AS Priority_Row_Number
FROM
	water_source
WHERE 
	type_of_water_source <> "tap_in_home"
GROUP BY
	source_id
ORDER BY 
	number_of_people_served DESC;

-- Task 6 Analysing queues
SELECT * FROM visits;

-- 1- How long did the survey take?
SELECT
	MAX(time_of_record), MIN(time_of_record) 
FROM
	visits;

SELECT
	DATEDIFF(MAX(time_of_record), MIN(time_of_record)) As Survey_time
FROM 
	visits;
-- Survey time is 924 days or 2.5 years
SELECT
	TIMESTAMPDIFF(DAY, MIN(time_of_record), MAX(time_of_record)) As Survey_time
FROM 
	visits;

-- 2- What is the average total queue time for water?
SELECT 
	ROUND(AVG(NULLIF(time_in_queue,0))) AS AVG_queue_time
FROM
	visits;

-- average total queue time = 123 
-- people take two hours to fetch water if they don't have a tap in their homes

-- 3- What is the average queue time on different days?
SELECT
	DAYNAME(time_of_record) AS day_of_week,
    ROUND(AVG(NULLIF(time_in_queue,0))) AS AVG_queue_time
FROM
	visits
GROUP BY
	DAYNAME(time_of_record)
ORDER BY
	 ROUND(AVG(NULLIF(time_in_queue,0))) DESC;
/*
 We used DAYNAME function b/c it will return the names of days --> 7 rows
 But if we used the DAY function it would return the days of month in numbers --> 31 rows
 And we are interested in the days of the week
 */
 -- From the result, we found that saturdays have the most average queue time
 
 -- 4- How can we communicate this information efficiently?
-- what time during the day people collect water
 
 SELECT
	HOUR(time_of_record) AS hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue,0))) AS AVG_queue_time
FROM
	visits
GROUP BY
	HOUR(time_of_record)
ORDER BY
	 ROUND(AVG(NULLIF(time_in_queue,0))) DESC;
-- the hour number is difficult to interpret. A format like 06:00 will be easier to read. Let's do it
SELECT
	TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue,0))) AS AVG_queue_time
FROM
	visits
GROUP BY
	TIME_FORMAT(TIME(time_of_record), '%H:00')
ORDER BY
	 ROUND(AVG(NULLIF(time_in_queue,0))) DESC;
     
     
-- breaking down the queue times for each hour of each day
/*
 For rows, we will use the hour of the day in that nice format, and then make each column a different day.
To filter a row we use WHERE, but using CASE() in SELECT can filter columns.
We can use a CASE() function for each day to separate the queue time column into a column for each day.
*/
 
SELECT
	TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
-- Sunday
	ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
		ELSE NULL
	END
	),0) AS Sunday,
-- Monday
	ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
		ELSE NULL
	END
	),0) AS Monday,
-- Tuesday
	ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
		ELSE NULL
	END
	),0) AS Tuesday,
-- Wednesday
	ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
		ELSE NULL
	END
	),0) AS Wednesday,
-- Thursday
	ROUND(AVG(
		CASE
        WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
        ELSE NULL
	END
	),0) As Thursday,
-- Friday
	ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
        ELSE NULL
	END
    ),0) AS Friday,
-- Saturday
	ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
		ELSE NULL
    END
    ),0) AS Saturday
FROM
visits
WHERE
time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY
hour_of_day
ORDER BY
hour_of_day;
 
 /*
 See if you can spot these patterns:
1. Queues are very long on a Monday morning and Monday evening as people rush to get water.
2. Wednesday has the lowest queue times, but long queues on Wednesday evening.
3. People have to queue pretty much twice as long on Saturdays compared to the weekdays. 
It looks like people spend their Saturdays queueing for water, perhaps for the week's supply?
4. The shortest queues are on Sundays, and this is a cultural thing. 
*/
 
 
 /* Q1: Which SQL query will produce the date format "DD Month YYYY" 
  from the time_of_record column in the visits table, as a single column? 
 Note: Monthname() acts in a similar way to DAYNAME().*/
 
 SELECT CONCAT(day(time_of_record), " ", monthname(time_of_record), " ", year(time_of_record)) FROM visits;
 
 SELECT day(time_of_record), monthname(time_of_record), year(time_of_record) FROM visits; -- wrong
 
-- Q2: You are working with an SQL query designed to calculate the Annual Rate of Change (ARC) for basic rural water services:
 
SELECT
	name,
    year,
    wat_bas_r,
	wat_bas_r - LAG(wat_bas_r) OVER (PARTITION BY name ORDER BY wat_bas_r) AS ARC 
FROM 
	global_water_access
ORDER BY
	name;
    
SELECT
	name,
    year,
    wat_bas_r,
	wat_bas_r - LAG(wat_bas_r) OVER (PARTITION BY name ORDER BY year) AS ARC 
FROM 
	global_water_access
ORDER BY
	name;
/* Q3:
What are the names of the two worst-performing employees who visited the fewest sites,
and how many sites did the worst-performing employee visit?
Modify your queries from the “Honouring the workers” section.
*/

SELECT
	COUNT(visit_count),
	SUM(visit_count) As number_of_visits,
    assigned_employee_id
FROM
	visits
GROUP BY 
	assigned_employee_id
ORDER BY 
	SUM(visit_count) DESC
LIMIT 2;
SELECT assigned_employee_id,
COUNT(record_id) AS number_of_visits
FROM visits
GROUP BY assigned_employee_id
ORDER BY number_of_visits 
LIMIT 2;

SELECT 
	employee_name
FROM
	employee
WHERE
	assigned_employee_id = 20 OR assigned_employee_id = 22;
    
-- Q4: What does the following query do?

SELECT 
    location_id,
    time_in_queue,
    visit_count,
    AVG(time_in_queue) OVER (PARTITION BY location_id ORDER BY visit_count) AS total_avg_queue_time
FROM 
    visits
WHERE 
	visit_count > 1 -- Only shared taps were visited > 1
ORDER BY 
    location_id, time_of_record;
    
/* Q5: 
One of our employees, Farai Nia, lives at 33 Angelique Kidjo Avenue.
What would be the result if we TRIM() her address?
TRIM('33 Angelique Kidjo Avenue  ')
*/
SELECT TRIM('33 Angelique Kidjo Avenue ');
-- Q6: How many employees live in Dahabu?

SELECT
	town_name,
    COUNT(town_name)
FROM
	employee
WHERE
	town_name = 'Dahabu'
GROUP BY
	town_name;
    
-- Q7: How many employees live in Harare, Kilimani?
SELECT
	town_name,
    province_name,
    COUNT(town_name)
FROM
	employee
GROUP BY
	town_name,
    province_name;

-- Q8: How many people share a well on average? Round your answer to 0 decimals

SELECT
	type_of_water_source,
    ROUND(AVG(number_of_people_served),0)
FROM
	water_source
WHERE
	type_of_water_source = 'well'
GROUP BY
	type_of_water_source;




















    

	








    
    
    
    
    
    
    
    
    