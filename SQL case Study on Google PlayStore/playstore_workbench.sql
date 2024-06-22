truncate table playstore;


select * from playstore;

load data infile 'C:\\Data_science_projects\\SQL practice\\SQL case Study on Google PlayStore\\playstore.csv'
into table playstore 
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

/* 1.You're working as a market analyst for a mobile app development company. Your task is to identify the most promising categories(TOP 5) for 
launching new free apps based on their average ratings. */

select Category, round(avg(Rating),2) as Rating from playstore where Price = 'Free' group by Category order by Rating desc limit 5;

/* 2. As a business strategist for a mobile app company, your objective is to pinpoint the three categories that generate the most revenue from paid apps.
This calculation is based on the product of the app price and its number of installations. */

select Category, avg(Revenue) as Revenue from (
select * , (Installs * Price) as Revenue from playstore where Type = 'Paid' 
)t group by category order by Revenue desc limit 3;

/* 3. As a data analyst for a gaming company, you're tasked with calculating the percentage of games within each category. 
This information will help the company understand the distribution of gaming apps across different categories. */

select *, (cnt/(select count(*) from playstore))*100 as Percentage from
(
select category , count(App) as cnt from playstore group by Category
)t order by Percentage desc;

/* 4. As a data analyst at a mobile app-focused market research firm, 
you'll recommend whether the company should develop paid or free apps for each category based on the  ratings of that category. */

with t1 as(
select Category , round(avg(Rating),2) as 'paid' from playstore where type = 'Paid' group by Category
), t2 as (
select Category , round(avg(Rating),2) as 'free' from playstore where type = 'Free' group by Category
)

select * , if (paid>free, 'Develop Paid Apps','Develop Free Apps') as 'Develop Apps' from 
(
select a.category,paid,free from t1 as a inner join t2 as b on a.Category = b.Category
)k;

/* 5.Suppose you're a database administrator, your databases have been hacked  and hackers are changing price of certain apps on the database , its taking long for IT team to 
neutralize the hack , however you as a responsible manager  dont want your data to be changed , do some measure where the changes in price can be recorded as you cant 
stop hackers from making changes */

-- creating table.
CREATE TABLE PriceChangeLog (
    App VARCHAR(255),
    Old_Price DECIMAL(10, 2),
    New_Price DECIMAL(10, 2),
    Operation_Type VARCHAR(10),
    Operation_Date TIMESTAMP
);

create table play as
SELECT * FROM PLAYSTORE;

DELIMITER //   
CREATE TRIGGER price_change_update
AFTER UPDATE ON play
FOR EACH ROW
BEGIN
    INSERT INTO pricechangelog (app, old_price, new_price, operation_type, operation_date)
    VALUES (NEW.app, OLD.price, NEW.price, 'update', CURRENT_TIMESTAMP);
END;
//
DELIMITER ;

SET SQL_SAFE_UPDATES = 0;
UPDATE play
SET price = 4
WHERE app = 'Infinite Painter';

SELECT * FROM pricechangelog;

drop trigger price_change_update;

/*6. your IT team have neutralize the threat,  however hacker have made some changes in the prices, but becasue of your measure you have noted the changes , 
now you want correct data to be inserted into the database.
*/
-- Here update + join is going to be used 

UPDATE play AS a
        INNER JOIN
    pricechangelog AS b ON a.app = b.app 
SET 
    a.price = b.old_price;

-- 7. As a data person you are assigned the task to investigate the correlation between two numeric factors: app ratings and the quantity of reviews.

SET @x = (SELECT ROUND(AVG(rating), 2) FROM playstore);
SET @y = (SELECT ROUND(AVG(reviews), 2) FROM playstore);    

with t as 
(
	select  *, round((rat*rat),2) as 'sqrt_x' , round((rev*rev),2) as 'sqrt_y' from
	(
		select  rating , @x, round((rating- @x),2) as 'rat' , reviews , @y, round((reviews-@y),2) as 'rev'from playstore
	)a                                                                                                                        
)
-- select * from  t
select  @numerator := round(sum(rat*rev),2) , @deno_1 := round(sum(sqrt_x),2) , @deno_2:= round(sum(sqrt_y),2) from t ; -- setp 4 
select round((@numerator)/(sqrt(@deno_1*@deno_2)),2) as corr_coeff;

/*8. Your boss noticed  that some rows in genres columns have multiple generes in them, which was creating issue when developing the  recommendor system from the data
he/she asssigned you the task to clean the genres column and make two genres out of it, rows that have only one genre will have other column as blank. */

select distinct(Genres) from playstore;
DELIMITER //
create function f_name(a varchar(200))
returns varchar(100)
deterministic
begin 
	set @l = locate(';',a);
    set @s = if(@l>0,left(a,@l-1),a);
    
    RETURN @s;
    
end //
DELIMITER ;

select f_name('Art & Design;Pretend Play');

DELIMITER //
create function l_name(a varchar(100))
returns varchar(100)
deterministic 
begin
   set @l = locate(';',a);
   set @s = if(@l = 0 ,' ',substring(a,@l+1, length(a)));
   
   return @s;
end //
DELIMITER ;

select app , genres , f_name(genres) as genre_1 ,l_name(genres) as genre_2 from playstore;

-- 9. Your senior manager wants to know which apps are  not performing as par in their particular category, however he is not interested in handling too many files or
-- list for every  category and he/she assigned  you with a task of creating a dynamic tool where he/she  can input a category of apps he/she  interested in and 
-- your tool then provides real-time feedback by
-- displaying apps within that category that have ratings lower than the average rating for that specific category.
select distinct(Category) from playstore;
DELIMITER // 
create procedure checking(in caste varchar(30))
begin 

select @c = (
select average from 
(
select Category, round(avg(Rating),2) as average from playstore group by Category
)m where Category='ART_AND_DESIGN'
);

select * from playstore where Category = caste and Rating<@c;

end //
DELIMITER ;

drop procedure checking;
call checking('ART_AND_DESIGN');
