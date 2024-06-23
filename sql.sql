-- p1_schema --

CREATE SCHEMA IF NOT EXISTS pandemic;

USE pandemic;

-- p2_normalized --

CREATE TABLE countries(
id INT PRIMARY KEY AUTO_INCREMENT,
code VARCHAR(8) UNIQUE,
country VARCHAR(32) NOT NULL UNIQUE
);

INSERT INTO countries (code, country)
SELECT DISTINCT code, entity FROM infectious_cases;

CREATE TABLE infectious_cases_normalized 
AS SELECT * FROM infectious_cases;

ALTER TABLE infectious_cases_normalized
ADD id INT PRIMARY KEY AUTO_INCREMENT FIRST,
ADD country_id INT AFTER id,
ADD CONSTRAINT fk_country_id FOREIGN KEY (country_id) REFERENCES countries(id);

SET SQL_SAFE_UPDATES = 0;

UPDATE infectious_cases_normalized i
INNER JOIN countries c ON i.code = c.code
SET i.country_id = c.id;

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE infectious_cases_normalized
DROP COLUMN entity,
DROP COLUMN code;

-- p3_select --

SELECT 
	id, 
    MAX(number_rabies) AS max_value, 
    MIN(number_rabies) AS min_value, 
	AVG(number_rabies) AS average_value 
FROM infectious_cases_normalized
WHERE number_rabies IS NOT NULL AND number_rabies <> ''
GROUP BY id
ORDER BY average_value DESC
LIMIT 10;

-- p4_diff --

ALTER TABLE infectious_cases_normalized 
ADD COLUMN start_date DATE NULL AFTER year,
ADD COLUMN cur_date DATE NULL AFTER start_date,
ADD COLUMN year_diff INT NULL AFTER cur_date;

DROP FUNCTION IF EXISTS fn_start_date;

DELIMITER //

CREATE FUNCTION fn_start_date(year INT)
RETURNS DATE
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result DATE;
    SET result = MAKEDATE(year, 1);
    RETURN result;
END //

DELIMITER ;

DROP FUNCTION IF EXISTS fn_cur_date;

DELIMITER //

CREATE FUNCTION fn_cur_date()
RETURNS DATE
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result DATE;
    SET result = CURDATE();
    RETURN result;
END //

DELIMITER ;

DROP FUNCTION IF EXISTS fn_year_diff;

DELIMITER //

CREATE FUNCTION fn_year_diff(cur_date DATE, start_date DATE)
RETURNS INT
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result INT;
    SET result = YEAR(cur_date) - YEAR(start_date);
    RETURN result;
END //

DELIMITER ;

SET SQL_SAFE_UPDATES = 0;

UPDATE infectious_cases_normalized
SET cur_date = fn_cur_date(),
start_date = fn_start_date(year),
year_diff = fn_year_diff(cur_date, start_date);

SET SQL_SAFE_UPDATES = 1;

SELECT * FROM infectious_cases_normalized;

-- p5_year_diff --

DROP FUNCTION IF EXISTS fn_cur_year_diff;

DELIMITER //

CREATE FUNCTION fn_cur_year_diff(start_date INT)
RETURNS INT
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result INT;
    SET result = YEAR(CURDATE()) - start_date;
    RETURN result;
END //

DELIMITER ;

SELECT
	Year, 
	curdate() as cur_date, 
    fn_cur_year_diff(Year) as year_diff
from infectious_cases;