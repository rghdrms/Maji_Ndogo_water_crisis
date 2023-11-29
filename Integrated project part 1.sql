-- Single line comments in SQL start with two dashes. 

/* 
Multiple line comments are enclosed like this  
*/

-- Task 1: Get to know our data
-- Show all of the tables. Selecting "SHOW TABLES;" with your cursor and running it, will run only that part.
SHOW TABLES;
-- We have 8 tables in our dataset and this number will increase as we moving on in the project

 -- location table
SELECT
   *
FROM
   location
LIMIT 5;
/* We can see that this table has information on a specific location, with an address, the province 
and town the location is in, and if it's in a city (Urban) or not.*/

-- visits table
SELECT
   *
FROM
   visits
LIMIT 5;
/* This is a list of location_id, source_id, record_id, and a date and time, so it makes sense that someone (assigned_employee_
id) visited some location (location_id) at some time (time_of_record ) and found a 'source' there (source_id).*/

-- water source table
SELECT
   *
FROM
   water_source
LIMIT 5;
/* Water sources are where people get their water from. it has the type of water source column which is recorded in different locations
and the number of people served in each source id. also it has source_id column as primary key and it is a foriegn key in the visits table*/

-- water quality table
SELECT
   *
FROM
   water_quality
LIMIT 5;
-- This table contains a quality score for each visit made about a water source that was assigned by a Field surveyor.

-- well pollution table
SELECT
   *
FROM
   well_pollution
LIMIT 5;
-- This table cotains information about the water source (well) and the degree of its pollution

-- employee table
SELECT
   *
FROM
   employee
LIMIT 5;

-- Task 2: Dive into the water sources
-- We need to understand the types of water sources we're dealing with.

SELECT
	DISTINCT type_of_water_source
FROM
	water_source;
-- We are dealing with 5 types of water sources (tap_in_home, tap_in_home_broken, well, shared_tap, river)

/* An important note on the home taps: About 6-10 million people have running water installed in their homes in Maji Ndogo, including
broken taps. If we were to document this, we would have a row of data for each home, so that one record is one tap. That means our
database would contain about 1 million rows of data, which may slow our systems down. For now, the surveyors combined the data of
many households together into a single record.*/

-- Task 3: Unpack the visits to water sources
-- We will retrieve all records from this table where the time_in_queue is more than some crazy time, say 500 min(8 hours).
SELECT
	*
FROM 
	visits
WHERE
	time_in_queue > 500;
-- Many people have to wait for more than 8 hours to get water!!

-- We want to know which source where people wait for long time by using the following quering
SELECT 
	DISTINCT water_source.type_of_water_source
FROM 
	visits
INNER JOIN 
	water_source
ON visits.source_id = water_source.source_id
WHERE 
	visits.time_in_queue > 500;
-- shared tap is the answer

-- Task 4: Assess the quality of water sources
/* We have water quality table that contains a quality score for each visit made about a water source that was assigned by a Field surveyor. 
They assigned a score to each source from 1, being terrible, to 10 for a good, clean water source in a home. Shared taps are not rated as 
high, and the score also depends on how long the queue times are.*/

/* Note the surveyors only made multiple visits to shared taps and did not revisit other types of water sources. So 
there should be no records of second visits to locations where there are good water sources, like taps in homes.*/

-- Let's check if the above note is true
SELECT 
	*
FROM
	water_quality
WHERE
	subjective_quality_score = 10
AND 
	visit_count = 2;
-- We get 218 rows of data. But this should not be happening

-- Task 5: Investigate any pollution issues

/* The biological column is in units of CFU/mL, so it measures how much contamination is in the water. 0 is clean, and anything more than
0.01 is contaminated.
Let's check the integrity of the data. The worst case is if we have contamination, but we think we don't. People can get sick, so we
need to make sure there are no errors here.*/

SELECT
	*
FROM
	well_pollution
WHERE 
	results = 'clean'
AND
	biological > 0.01;

/* It seems like, in some cases, if the description field begins with the word “Clean”, the results have been classified as “Clean” in the results
column, even though the biological column is > 0.01.*/

-- let's look at the descriptions. We need to identify the records that mistakenly have the word Clean in the description
-- To find these descriptions, search for the word Clean with additional characters after it.
SELECT
	*
FROM
	well_pollution
WHERE
	description LIKE "Clean_%";
-- The query returned 38 wrong descriptions.

/*
Now we need to fix these descriptions. 
Looking at the results we can see two different descriptions that we need to fix:
1. All records that mistakenly have Clean Bacteria: E. coli should updated to Bacteria: E. coli
2. All records that mistakenly have Clean Bacteria: Giardia Lamblia should updated to Bacteria: Giardia Lamblia
The second issue we need to fix is in our results column. We need to update the results column from Clean to Contaminated: Biological
where the biological column has a value greater than 0.01.*/

-- A safer way to do the UPDATE is by testing the changes on a copy of the table first. so we will create a copy of the well pollution table

CREATE TABLE
	md_water_services.well_pollution_copy
AS (
	SELECT
		*
	FROM
		md_water_services.well_pollution
);

UPDATE
	well_pollution_copy
SET
	description = 'Bacteria: E. coli'
WHERE
	description = 'Clean Bacteria: E. coli';
UPDATE
	well_pollution_copy
SET
	description = 'Bacteria: Giardia Lamblia'
WHERE
	description = 'Clean Bacteria: Giardia Lamblia';
UPDATE
	well_pollution_copy
SET
	results = 'Contaminated: Biological'
WHERE
	biological > 0.01 AND results = 'Clean';
 
 -- Let's check if we fixed the errors
 
SELECT
	*
FROM
	well_pollution_copy
WHERE
	description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);

-- Now we can update the original table
UPDATE
	well_pollution
SET
	description = 'Bacteria: E. coli'
WHERE
	description = 'Clean Bacteria: E. coli';
UPDATE
	well_pollution
SET
	description = 'Bacteria: Giardia Lamblia'
WHERE
	description = 'Clean Bacteria: Giardia Lamblia';
UPDATE
	well_pollution
SET
	results = 'Contaminated: Biological'
WHERE
	biological > 0.01 AND results = 'Clean';
    
DROP TABLE
md_water_services.well_pollution_copy;