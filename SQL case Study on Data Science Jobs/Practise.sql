select * from salaries;
/*1.	You're a Compensation analyst employed by a multinational corporation. 
Your Assignment is to Pinpoint Countries who give work fully remotely, for the title 'managers’ 
Paying salaries Exceeding $90,000 USD */
select distinct company_location from salaries where job_title like '%Manager%' and salary_in_usd > 90000 and remote_ratio = 100;

/* 
2.	AS a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients IN large tech firms. 
you're tasked WITH Identifying top 5 Country Having greatest count of large (company size) number of companies.
*/

select company_location , count(*) as cnt  from 
(
select * from salaries where experience_level = 'EN' and company_size = 'L'
)t group by company_location 
order by cnt desc 
limit 5;

/* 
3.	Picture yourself AS a data scientist Working for a workforce management platform. 
Your objective is to calculate the percentage of employees. 
Who enjoy fully remote roles WITH salaries Exceeding $100,000 USD, Shedding light ON the attractiveness of high-paying remote positions IN today's job market.
*/
set @total = (select count(*) from salaries where salary_in_usd > 100000);
set @count = (select count(*) from salaries where salary_in_usd >100000 and remote_ratio=100);
set @percentage = round(((select @count)/(select @total))*100,2);

select @percentage as 'Percent';

/*4.	Imagine you're a data analyst Working for a global recruitment agency. Your Task is to identify the Locations where entry-level average salaries exceed the 
average salary for that job title in market for entry level, helping your agency guide candidates towards lucrative countries.*/
SELECT company_locatiON, t.job_title, average_per_country, average FROM 
(
	SELECT company_locatiON,job_title,AVG(salary_IN_usd) AS average_per_country FROM  salaries WHERE experience_level = 'EN' 
	GROUP BY  company_locatiON, job_title
) AS t 
INNER JOIN 
( 
	 SELECT job_title,AVG(salary_IN_usd) AS average FROM  salaries  WHERE experience_level = 'EN'  GROUP BY job_title
) AS p 
ON  t.job_title = p.job_title WHERE average_per_country> average;
    

/*5. You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries. Your job is to Find out for each job title which
Country pays the maximum average salary. This helps you to place your candidates IN those countries.*/

SELECT company_locatiON , job_title , average FROM
(
SELECT *, dense_rank() over (partitiON by job_title order by average desc)  AS num FROM 
(
SELECT company_locatiON , job_title , AVG(salary_IN_usd) AS 'average' FROM salaries GROUP BY company_locatiON, job_title
)k
)t  WHERE num=1;

/*6.  AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary trends across different company Locations.
 Your goal is to Pinpoint Locations WHERE the average salary Has consistently Increased over the Past few years 
 (Countries WHERE data is available for 3 years Only(this and pst two years) 
 providing Insights into Locations experiencing Sustained salary growth.
 */

with A as (
select * from salaries where company_location in (
select company_location from (
select company_location, avg(salary_in_usd),count(distinct work_year) as cnt from salaries where work_year >= year(current_date())-2 
group by company_location having cnt = 3
)t
)
) 
select company_location,
max(case when work_year = 2022 then average end) as avg_sal_22,
max(case when work_year = 2023 then average end) as avg_sal_23,
max(case when work_year = 2024 then average end) as avg_sal_24
from 
(
select company_location, work_year, avg(salary_in_usd) as average from A group by company_location , work_year
)q group by company_location having avg_sal_24>avg_sal_23 and avg_sal_23>avg_sal_22;

/* 
According to the job title 
 */
with A as (
select * from salaries where company_location in (
select company_location from (
select company_location, avg(salary_in_usd),count(distinct work_year) as cnt from salaries where work_year >= year(current_date())-2 
group by company_location having cnt = 3
)t
)
) 
select company_location, job_title,
max(case when work_year = 2022 then average end) as avg_sal_22,
max(case when work_year = 2023 then average end) as avg_sal_23,
max(case when work_year = 2024 then average end) as avg_sal_24
from 
(
select company_location,job_title, work_year, avg(salary_in_usd) as average from A group by company_location , work_year,job_title
)q group by company_location, job_title having avg_sal_24>avg_sal_23 and avg_sal_23>avg_sal_22;


/* 7.	Picture yourself AS a workforce strategist employed by a global HR tech startup. Your missiON is to determINe the percentage of  fully remote work for each 
 experience level IN 2021 and compare it WITH the correspONdINg figures for 2024, highlightINg any significant INcreASes or decreASes IN remote work adoptiON
 over the years.*/

select * from (
select *,ROUND((((cnt)/total)*100),2) AS '2021 remote %' from 
(
	select a.experience_level, total,cnt from 
	(
		select experience_level, count(*) as total from salaries where work_year=2021 group by experience_level
	)a inner join 
	(
		select experience_level, count(*) as cnt from salaries where work_year=2021 and remote_ratio = 100 group by experience_level
	)b on a.experience_level = b.experience_level
)t
)m inner join 
(
select *,ROUND((((cnt_24)/total_24)*100),2) AS '2024 remote %' from 
(
	select k.experience_level, total_24,cnt_24 from 
	(
		select experience_level, count(*) as total_24 from salaries where work_year=2024 group by experience_level
	)k inner join 
		(
		select experience_level, count(*) as cnt_24 from salaries where work_year=2024 and remote_ratio = 100 group by experience_level
		)l on k.experience_level = l.experience_level
)t
)n on m.experience_level = n.experience_level;

/* 8. AS a compensatiON specialist at a Fortune 500 company, you're tASked WITH analyzINg salary trends over time. Your objective is to calculate the average 
salary INcreASe percentage for each experience level and job title between the years 2023 and 2024, helpINg the company stay competitive IN the talent market.*/	

with a as (
select experience_level ,job_title , work_year, round(avg(salary_in_usd),2) as average from salaries where work_year in (2023,2024) 
group by experience_level , job_title , work_year
)


select *, round(((work_year_24-work_year_23)/work_year_23)*100,2) as percent_change from 
(
select experience_level , job_title,
max(case when work_year = 2023 then average end) work_year_23,
max(case when work_year = 2024 then average end) work_year_24 
from a group by experience_level, job_title
)b where (((work_year_24-work_year_23)/work_year_23)*100) is not null;

/* 9. You're a database administrator tasked with role-based access control for a company's employee database. Your goal is to implement a security measure where employees
 in different experience level (e.g.Entry Level, Senior level etc.) can only access details relevant to their respective experience_level, ensuring data 
 confidentiality and minimizing the risk of unauthorized access.*/
select distinct experience_level from salaries;
 Show privileges;
-- @ for host address and % means he can connect to host address (he as all access) 

CREATE USER 'Entry_level'@'%' IDENTIFIED BY 'EN';
CREATE USER 'Junior_Mid_level'@'%' IDENTIFIED BY ' MI '; 
CREATE USER 'Intermediate_Senior_level'@'%' IDENTIFIED BY 'SE';
CREATE USER 'Expert Executive-level '@'%' IDENTIFIED BY 'EX ';

create view entry_level as 
(
select * from salaries where experience_level = 'EN'
);

grant select on new_schema.salaries to 'Entry_level'@'%';

/* 10.	You are working with an consultancy firm, your client comes to you with certain data and preferences such as 
( their year of experience , their employment type, company location and company size )  and want to make an transaction into different domain in data industry
(like  a person is working as a data analyst and want to move to some other domain such as data science or data engineering etc.)
your work is to  guide them to which domain they should switch to base on  the input they provided, so that they can now update thier knowledge as  per the suggestion/.. 
The Suggestion should be based on average salary.*/ 

DELIMITER //
create PROCEDURE AverageSalary(IN exp_lev VARCHAR(2), IN emp_type VARCHAR(3), IN comp_loc VARCHAR(2), IN comp_size VARCHAR(2))
BEGIN
    SELECT job_title, experience_level, company_location, company_size, employment_type, ROUND(AVG(salary), 2) AS avg_salary 
    FROM salaries 
    WHERE experience_level = exp_lev AND company_location = comp_loc AND company_size = comp_size AND employment_type = emp_type 
    GROUP BY experience_level, employment_type, company_location, company_size, job_title order by avg_salary desc ;
END//
DELIMITER ;
-- Deliminator  By doing this, you're telling MySQL that statements within the block should be parsed as a single unit until the custom delimiter is encountered.

call AverageSalary('EN','FT','AU','S');

drop procedure AverageSalary

