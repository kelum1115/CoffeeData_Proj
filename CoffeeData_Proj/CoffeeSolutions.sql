use coffeedata;

-- Data analysis 
-- 1.  Amount of people in each city estimated to drink coffee given that 25% of the population does
select city_name, 
round((population * 0.25) / 1000000, 2) as coffee_drinker_in_mil,
city_rank 
from city
order by 2 DESC;
-- 2. Total revenue generated from coffee sales across all cities in the last qtr of 2023
select cc.city_name,
sum(s.total) as total_revenue 
from sales as s 
join customer as c on s.customer_id = c.customer_id
join city as cc on cc.city_id = c.city_id
where year(s.sale_date) = 2023 and quarter(s.sale_date) = 4
group by cc.city_name
order by total_revenue desc; 
-- 3. How many units of each coffee product have been sold?
select p.product_name, 
count(s.sale_id) as total_orders
from products as p
left join sales as s on s.product_id = p.product_id
group by p.product_name
order by total_orders desc;
-- 4. What is the average sales amount per customer in each city
select cc.city_name,
sum(s.total) as total_revenue,
count(distinct s.customer_id) as total_c,
round(sum(s.total)/count(distinct s.customer_id), 2) as avg_sale_per_c
from sales as s
join customer as c on s.customer_id = c.customer_id
join city as cc on cc.city_id = c.city_id
group by cc.city_name
order by total_revenue desc;
-- 5. Provide a list of cities along with their populations and estimated coffee consumers.
select cc.city_name, cc.population,
round((cc.population * 0.25) / 1000000, 2) as coffee_con,
count(distinct c.customer_id) as unique_c
from city as cc
left join customer as c on c.city_id = cc.city_id
group by cc.city_id, cc.city_name, cc.population
order by coffee_con desc;
-- 6. Top 3 products in each city on sales volume *
select * from -- table
(
select cc.city_name, p.product_name, 
count(s.sale_id) as total_orders,
dense_rank() over(partition by cc.city_name order by count(s.sale_id) desc) as rank_num
from sales as s
join products as p on s.product_id = p.product_id
join customer as c on c.customer_id = s.customer_id
join city as cc on cc.city_id = c.city_id
group by cc.city_name, p.product_name
order by cc.city_name, total_orders desc
) as t1
where rank_num <= 3;
-- 7. How many unique customers are there in each city who have purchased coffee products?
select cc.city_name,
count(distinct c.customer_id) as unique_cus
from city as cc
left join customer as c on c.city_id = cc.city_id
join sales as s on s.customer_id = c.customer_id
where s.product_id <= 14
group by cc.city_name
order by unique_cus desc;
-- 8. Find each city and their average sale per customer and avg rent per customer? *
select cc.city_name, cc.estimated_rent, 
sum(s.total) as total_revenue,
count(distinct s.customer_id) as total_c,
round(sum(s.total)/count(distinct s.customer_id), 2) as avg_sale_per_c,
round(cc.estimated_rent/count(distinct s.customer_id), 2) as avg_rent
from sales as s
join customer as c on s.customer_id = c.customer_id
join city as cc on cc.city_id = c.city_id
group by cc.city_name, cc.estimated_rent
order by avg_sale_per_c desc;
-- 9. Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
with monthly_sales 
as
(
	select cc.city_name,
	Month(sale_date) as month,
	year(sale_date) as year,
	sum(s.total) as total_revenue
	from sales as s
	join customer as c on c.customer_id = s.customer_id
	join city as cc on cc.city_id = c.city_id
	group by 1, 2, 3
	order by 1, 2, 3
),
growth_ratio
as
(
select city_name, month, year,
total_revenue as cr_month_sale,
lag(total_revenue, 1) over(partition by city_name order by year, month) as last_month_sale
from monthly_sales
)
select city_name, month, year, cr_month_sale, last_month_sale, round((cr_month_sale-last_month_sale) / last_month_sale * 100, 2) as growth_ratio
from growth_ratio;
-- 10. Identify top 3 city based on highest sales, return city name, total sale, total sale, total rent, total customers, estimated coffee consumers.
with city_table
as
(
	select cc.city_name, sum(s.total) as total_revenue, cc.estimated_rent as total_rent, count(distinct s.customer_id) as total_c, round(sum(s.total)/count(distinct s.customer_id), 2) as avg_sale_per_c,
	round(cc.estimated_rent/count(distinct s.customer_id), 2) as avg_rent
	from sales as s
	join customer as c on s.customer_id = c.customer_id
	join city as cc on cc.city_id = c.city_id
	group by cc.city_name, cc.estimated_rent
	order by avg_sale_per_c desc
),
city_rent
as
(
	select city_name, estimated_rent, round((population * 0.25)/ 1000000, 3) as est_coffee_c_mil
	from city
)
select cr.city_name, total_revenue, cr.estimated_rent as total_rent, ct.total_c, est_coffee_c_mil, ct.avg_sale_per_c, round(cr.estimated_rent/ct.total_c, 2) as avg_rent
from city_rent as cr
join city_table as ct on cr.city_name = ct.city_name 
order by total_revenue desc