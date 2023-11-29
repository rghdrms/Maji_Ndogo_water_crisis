-- Task 1 Joining pieces toghether: 
/*
Finding the data we need across the table:

• All of the information about the location of a water source is in the location table, specifically 
the town and province of that water source.
• water_source has the type of source and the number of people served by each source.
• visits has queue information, and connects source_id to location_id. There were multiple
visits to sites, so we need to be careful to include duplicate data (visit_count > 1 ).
• well_pollution has information about the quality of water from only wells, so we need to keep 
that in mind when we join this table.
*/

/*
Are there any specific provinces, or towns where some sources are more abundant?
To answer this question, we will need province_name and town_name from the location table. We also need to know 
type_of_water_source and number_of_people_served from the water_source table.
*/

SELECT
	province_name,
    town_name,
    type_of_water_source,
    number_of_people_served
FROM
	location
JOIN
	visits
ON
	location.location_id = visits.location_id
JOIN
	water_source
ON
	visits.source_id = water_source.source_id
WHERE 
	visits.visit_count = 1;
/*
--> we used visits table to link between location and water_source tables b/c they are not have columns in common    
--> We added where visits.visit_count = 1 as a filter b/c For some locations, there are multiple records for the same location.
If we aggregate with these duplicate data, we will include these rows, so our results will be incorrect.
--> we have used the count_visits and location_id from visits table, After we verified that the table is joined correctly, 
we can remove the location_id and visit_count columns.
*/
-- Add the location_type column from location and time_in_queue from visits to our results set from the previous query.
SELECT
	province_name,
    town_name,
    type_of_water_source,
    location_type,
    number_of_people_served,
    time_in_queue
FROM
	location
JOIN
	visits
ON
	location.location_id = visits.location_id
JOIN
	water_source
ON
	visits.source_id = water_source.source_id
WHERE 
	visits.visit_count = 1;

-- Grab the results from the well_pollution table
    
SELECT
	location.province_name,
    location.town_name,
    water_source.type_of_water_source,
    location.location_type,
    water_source.number_of_people_served,
    visits.time_in_queue,
    well_pollution.results
FROM
	visits
LEFT JOIN
	well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
	location
ON location.location_id = visits.location_id
INNER JOIN
	water_source
ON water_source.source_id = visits.source_id
WHERE
	visits.visit_count = 1;
/*
we used LEFT JOIN after visits b/c the well_pollution table contained only data for well. If we just use JOIN, we
will do an inner join, so that only records that are in well_pollution AND visits will be joined. We have to use
 a LEFT JOIN to join the results from the well_pollution table for well sources, and will be NULL for all of the rest.
 */
-- I will create a view called combined_analysis_table to save the resultset of the previous query
-- also we can a CTE
CREATE VIEW combined_analysis_table AS
SELECT
	location.province_name,
    location.town_name,
    water_source.type_of_water_source,
    location.location_type,
    water_source.number_of_people_served,
    visits.time_in_queue,
    well_pollution.results
FROM
	visits
LEFT JOIN
	well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
	location
ON location.location_id = visits.location_id
INNER JOIN
	water_source
ON water_source.source_id = visits.source_id
WHERE
	visits.visit_count = 1;
    
-- Task 2 the last analysis
/*
We're building a pivot table. we want to break down our data into provinces or towns and source types. 
If we understand where the problems are, and what we need to improve at those locations
*/
WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
	province_name,
	SUM(number_of_people_served) AS total_ppl_serv
FROM
	combined_analysis_table
GROUP BY
	province_name
)
/* SELECT -- this SELECT statement retrieve the result of the province_total CTE
	*
FROM
	province_totals;*/
SELECT
	ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
	ROUND((SUM(CASE WHEN type_of_water_source = 'river'
		THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
		THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
		THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
		THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN type_of_water_source = 'well'
		THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
	combined_analysis_table ct
JOIN
	province_totals pt ON ct.province_name = pt.province_name
GROUP BY
	ct.province_name
ORDER BY
	ct.province_name;
/*
--> The main query selects the province names, and then we create a bunch of columns for each type of 
water source with CASE statements, sum each of them together, and calculate percentages.    
--> We join the province_totals table to our combined_analysis_table so that the correct value for each
province's pt.total_ppl_serv value is used.    
--> Finally we group by province_name to get the provincial percentages.    
    
/*
What did we find?
1- Sokoto has the largest population of people drinking river water. We should send our drilling equipment to Sokoto
first, so people can drink safe filtered water from a well. 
2- The majority of water from Amanzi comes from home taps, but half of these home taps don't work because the infrastructure is broken. 
We need to send out engineering teams to look at the infrastructure in Amanzi first. Fixing a large pump, treatment plant or 
reservoir means that thousands of people will have running water. This means they will also not have to queue for water, so 
we improve two things at once.    
3- Akatsi and Kilimani have the lagest population of people get thier water from shared taps and low population depend on home taps.
*/

/*
Let's aggregate the data per town now. You might think this is simple, but one little town makes this hard. 
Recall that there are two towns in Maji Ndogo called Harare. One is in Akatsi, and one is in Kilimani. Amina 
is another example. So when we just aggregate by town, SQL doesn't distinguish between the different Harare's, 
so it combines their results.
To get around that, we have to group by province first, then by town, so that the duplicate towns are distinct 
because they are in different towns.    
*/
    
WITH town_totals AS(  -- This CTE calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
SELECT 
	province_name,
    town_name,
    SUM(number_of_people_served) AS total_ppl_serv
FROM
	combined_analysis_table
GROUP BY
	province_name,
    town_name
)
SELECT
		ct.province_name,
        ct.town_name,
        ROUND((SUM(CASE WHEN type_of_water_source = 'river'
			THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS river,
        ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
			THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS shared_tap,
        ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
			THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS tap_in_home,
        ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
			THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
		ROUND((SUM(CASE WHEN type_of_water_source = 'well'
			THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS well
FROM 
	combined_analysis_table ct
JOIN
	town_totals tt
ON -- Since the town names are not unique, we have to join on a composite key
	ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
	ct.province_name,
    ct.town_name
ORDER BY
	ct.province_name,
    ct.town_name;
    
-- let's store it as a temporary table first, so it is quicker to access.

CREATE TEMPORARY TABLE town_aggregated_water_access   
    WITH town_totals AS(  -- This CTE calculates the population of each town
	-- Since there are two Harare towns, we have to group by province_name and town_name
	SELECT 
		province_name,
		town_name,
		SUM(number_of_people_served) AS total_ppl_serv
	FROM
		combined_analysis_table
	GROUP BY
		province_name,
		town_name
	)
	SELECT
			ct.province_name,
			ct.town_name,
			ROUND((SUM(CASE WHEN type_of_water_source = 'river'
				THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS river,
			ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
				THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS shared_tap,
			ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
				THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS tap_in_home,
			ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
				THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
			ROUND((SUM(CASE WHEN type_of_water_source = 'well' 
				THEN number_of_people_served ELSE 0 END) * 100 / tt.total_ppl_serv), 0) AS well
	FROM 
		combined_analysis_table ct
	JOIN
		town_totals tt
	ON -- Since the town names are not unique, we have to join on a composite key
		ct.province_name = tt.province_name AND ct.town_name = tt.town_name
	GROUP BY -- We group by province first, then by town.
		ct.province_name,
		ct.town_name
	ORDER BY
		ct.province_name,
		ct.town_name;

SELECT * FROM town_aggregated_water_access;
select province_name from town_aggregated_water_access ;

/* If you close the database connection, it deletes the table, so you have to run it again each time you 
start working in MySQL. The benefit is that we can use the table to do more calculations, without running 
the whole query each time.*/
 -- Let's order by river column DESC to see if we were right about Sokoto province or not
 SELECT
	*
FROM
	town_aggregated_water_access
ORDER BY
	river DESC;
/* 
yes, we were right. But look at the tap_in_home percentages in Sokoto too. Some of our citizens are forced 
to drink unsafe water from a river, while a lot of people have running water in their homes in Sokoto. 
Large disparities in water access like this often show that the wealth distribution in Sokoto is very unequal.
We should mention this in our report. We should also send our drilling teams to Sokoto first to drill some 
wells for the people who are drinking river water, specifically the rural parts and the city of Bahari.
*/
/*
But look at the tap_in_home percentages in Sokoto too. Some of our citizens are forced to drink unsafe water from 
a river, while a lot of people have running water in their homes in Sokoto. Large disparities in water access like 
this often show that the wealth distribution in Sokoto is very unequal. We should mention this in our report. We should 
also send our drilling teams to Sokoto first to drill some wells for the people who are drinking river water, specifically the 
rural parts and the city of Bahari.
*/

-- sort the data by province_name next and look at the data for Amina in Amanzi
 SELECT
	*
FROM
	town_aggregated_water_access
ORDER BY
	province_name;
/*
only 3% of Amina's citizens have access to running tap water in their homes. More than half of the people in Amina have 
taps installed in their homes, but they are not working.
*/
 -- The following query will answer which town has the highest ratio of people who have taps, but have no running water?
SELECT
	province_name,
	town_name,
	ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
FROM
	town_aggregated_water_access
ORDER BY 
	Pct_broken_taps DESC;
-- We can see that Amina has infrastructure installed, but almost none of it is working
-- Task 3 summary report

-- Task 4 Practical plan
/*
The goal of this step is to create a table where our teams have the information they need to fix, upgrade and repair 
water sources. They will need the addresses of the places they should visit (street address, town, province), the type 
of water source they should improve, and what should be done to improve it. We should also make space for them in the 
database to update us on their progress. We need to know if the repair is complete, and the date it was completed, and give 
them space to upgrade the sources. Let's call this table Project_progress.
*/

-- This query creates the Project_progress table:

CREATE TABLE Project_progress (
	Project_id SERIAL PRIMARY KEY,
	/* Project_id −− Unique key for sources in case we visit the same
	source more than once in the future.
	*/
	source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
	/* source_id −− Each of the sources we want to improve should exist,
	and should refer to the source table. This ensures data integrity.
	*/
	Address VARCHAR(50), -- Street address
	Town VARCHAR(30),
	Province VARCHAR(30),
	Source_type VARCHAR(50),
	Improvement VARCHAR(50), -- What the engineers should do at that place
	Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
		/* Source_status −− We want to limit the type of information engineers can give us, so we
		limit Source_status.
		− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
		− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.
		*/
	Date_of_completion DATE, -- Engineers will add this the day the source has been upgraded.
	Comments TEXT -- Engineers can leave comments. We use a TEXT type that has no limit on char length
	);
     
-- 1.
/*
Project_progress_query: 
--> It joins the location, visits, and well_pollution tables to the water_source table. Since well_pollution only has data for wells, we have
to join those records to the water_source table with a LEFT JOIN and we used visits to link the various id's together.
--> First things first, let's filter the data to only contain sources we want to improve by thinking through the logic first.
	1. Only records with visit_count = 1 are allowed.
	2. Any of the following rows can be included:
		a. Where shared taps have queue times over 30 min.
		b. Only wells that are contaminated are allowed -- So we exclude wells that are Clean
		c. Include any river and tap_in_home_broken sources.
*/
SELECT
	location.address,
	location.town_name,
	location.province_name,
	water_source.source_id,
	water_source.type_of_water_source,
	well_pollution.results
FROM
	water_source
LEFT JOIN
	well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
	visits ON water_source.source_id = visits.source_id
INNER JOIN
	location ON location.location_id = visits.location_id
WHERE 
	visits.visit_count = 1
AND (
	well_pollution.results != 'clean'
OR 
	water_source.type_of_water_source IN ('river', 'tap_in_home_broken')
OR 
	water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30
    );
	
/*
What are the improvemnts that we need to do?
1. Rivers --> Drill wells
2. wells: if the well is contaminated with chemicals → Install RO filter
3. wells: if the well is contaminated with biological contaminants → Install UV and RO filter
4. shared_taps: if the queue is longer than 30 min (30 min and above) → Install X taps nearby where X number of taps is calculated using X
= FLOOR(time_in_queue / 30).
5. tap_in_home_broken → Diagnose local infrastructure
*/
-- First insert the result of project_progress_query into project_progress table: 

INSERT INTO project_progress ( source_id, address, town, province, source_type)
SELECT
	water_source.source_id,
	location.address,
	location.town_name,
	location.province_name,
	water_source.type_of_water_source
FROM
	water_source
LEFT JOIN
	well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
	visits ON water_source.source_id = visits.source_id
INNER JOIN
	location ON location.location_id = visits.location_id
WHERE 
	visits.visit_count = 1
AND (
	well_pollution.results != 'clean'
OR 
	water_source.type_of_water_source IN ('river', 'tap_in_home_broken')
OR 
	water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30
    );

-- Second, update the improvement column 
    
UPDATE project_progress
LEFT JOIN well_pollution ON project_progress.source_id = well_pollution.source_id
JOIN visits ON project_progress.source_id = visits.source_id
SET Improvement =
    CASE
        WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
        WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN project_progress.source_type = 'river' THEN 'drill well'
        WHEN project_progress.source_type = 'shared_tap' AND visits.time_in_queue >= 30 THEN CONCAT('Install ', FLOOR(visits.time_in_queue / 30), ' taps nearby')
        WHEN project_progress.source_type = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
        ELSE NULL
    END;

-- Q7 What is the maximum percentage of the population using rivers in a single town in the Amanzi province?
SELECT
	*
FROM
	town_aggregated_water_access
WHERE
	province_name = 'amanzi'
ORDER BY
	river DESC;
    
SELECT
	*
FROM
	town_aggregated_water_access
ORDER BY
	shared_tap DESC;

-- Q8: In which province(s) do all towns have less than 50% access to home taps (including working and broken)?
SELECT province_name
FROM town_aggregated_water_access
GROUP BY province_name
HAVING MAX(tap_in_home) < 50 AND MAX(tap_in_home_broken) < 50;

SELECT
project_progress.Project_id, 
project_progress.Town, 
project_progress.Province, 
project_progress.Source_type, 
project_progress.Improvement,
Water_source.number_of_people_served,
RANK() OVER(PARTITION BY Province ORDER BY number_of_people_served)
FROM  project_progress 
JOIN water_source 
ON water_source.source_id = project_progress.source_id
WHERE Improvement = "Drill Well"
ORDER BY Province DESC, number_of_people_served
	


