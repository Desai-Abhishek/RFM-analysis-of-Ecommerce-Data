use analysis;

--- Reading data

select * from sales_data;

---checking unique values 

select distinct STATUS from sales_data;
select distinct year_id from sales_data;
select distinct PRODUCTLINE from sales_data;
select distinct COUNTRY from sales_data;
select distinct DEALSIZE from sales_data;
select distinct TERRITORY from sales_data;


--- sales by prooductline

select PRODUCTLINE,convert(decimal(10,2),sum(sales)) as Total_sales from sales_data
group by PRODUCTLINE
order by Total_sales desc;

--- sales by year

select YEAR_ID,convert(decimal(10,2),sum(sales)) as Total_sales from sales_data
group by YEAR_ID
order by Total_sales desc;

	--- reason - In year 2005 sales is low because company operate in half year only 
	select distinct MONTH_ID from sales_data
	where YEAR_ID=2003;

	select distinct MONTH_ID from sales_data
	where YEAR_ID=2004;

	select distinct MONTH_ID from sales_data
	where YEAR_ID=2005;
	
---what was the best month for sales in a each year? how much revenue?

with cte as(
select YEAR_ID,MONTH_ID,SUM(sales) as Revenue,COUNT(ordernumber) as frequency  from sales_data
group by YEAR_ID,MONTH_ID
),
cte1 as(
select *,DENSE_RANK() over(partition by YEAR_ID order by Revenue desc) as rnk from cte 
)
select * from cte1
where rnk=1
order by YEAR_ID,MONTH_ID;

---what product do they sell in november? how much revenue?

with cte as(
select YEAR_ID,MONTH_ID,PRODUCTLINE,SUM(sales) as Revenue,COUNT(ordernumber) as frequency  from sales_data
where MONTH_ID=11
group by YEAR_ID,MONTH_ID,PRODUCTLINE
),
cte1 as(
select *,DENSE_RANK() over(partition by YEAR_ID,MONTH_ID order by Revenue desc) as rnk from cte 
)
select * from cte1
order by YEAR_ID,MONTH_ID;


---who is best customer 
---
create view customers_data

as

with cte as(	
	select
		CUSTOMERNAME,
		SUM(sales) as Monetary_value,
		COUNT(ordernumber) as Frequency,
		MAX(orderdate) as last_order_date,
		(select MAX(orderdate) from sales_data) as max_order_date,
		DATEDIFF(day,MAX(orderdate),(select MAX(orderdate) from sales_data)) as Recency 
	from sales_data
	group by CUSTOMERNAME
),
cte1 as(
	select 
		*,
		NTILE(4) over(order by Recency desc)  as Recency_rnk,
		NTILE(4) over(order by Frequency)     as Frequency_rnk,
		NTILE(4) over(order by Monetary_value)as Monetary_value_rnk 
	from cte
)
select 
	*,
	cast(Recency_rnk as varchar)+cast(Frequency_rnk as varchar)+cast(Monetary_value_rnk as varchar) as 'All_rank'
from cte1
---

select 
	CUSTOMERNAME,Recency_rnk,Frequency_rnk,Monetary_value_rnk,All_rank,
	case 
	when All_rank in (111, 112 , 121, 122, 123, 132, 211, 212, 221, 114, 141) then 'lost_customers'  --lost customers
	when All_rank in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
	when All_rank in (311, 411, 331, 421, 412) then 'new customers'
	when All_rank in (222, 223, 233, 232, 234, 322) then 'potential churners'
	when All_rank in (323, 333,321, 422, 332, 432, 423) then 'active' --(Customers who buy often & recently, but at low price points)
	when All_rank in (433, 434, 443, 444) then 'loyal'
	end segmentation_customers
from customers_data

---what product are most often sold together?

select ORDERNUMBER,STRING_AGG(PRODUCTCODE,',') as productcode
from sales_data
group by ORDERNUMBER
order by LEN(STRING_AGG(PRODUCTCODE,','));

---What city has the highest number of sales in a specific country

--
CREATE PROCEDURE highest_sales_by_city_specific_country
@country varchar(30)

as

select city, SUM(sales) as Revenue
from sales_data
where country like @country
group by city
order by Revenue desc;
--
EXECUTE highest_sales_by_city_specific_country 'UK';
EXECUTE highest_sales_by_city_specific_country 'USA';
EXECUTE highest_sales_by_city_specific_country 'Italy';

---What is the best product in a specific country ?

--
CREATE PROCEDURE best_product_in_specific_country
@country varchar(30)

as

select country, YEAR_ID, PRODUCTLINE, SUM(sales) as Revenue
from sales_data
where country like @country
group by  country, YEAR_ID, PRODUCTLINE
order by Revenue desc

--
EXECUTE best_product_in_specific_country 'UK';
EXECUTE best_product_in_specific_country 'USA';
EXECUTE best_product_in_specific_country 'Italy';