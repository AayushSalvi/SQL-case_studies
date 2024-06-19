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
