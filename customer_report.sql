/*
===============================================================================
Customer Report
===============================================================================

Purpose:
 - This report consolidates key customer metrics and behaviors

Highlights:
1. Gathers essential fields such as names, ages, and transaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
   - total orders
   - total sales
   - total quantity purchased
   - total products
   - lifespan (in months)

4. Calculates valuable KPIs:
   - recency (months since last order)
   - average order value
   - average monthly spend
===============================================================================
*/

create view customer_report_gold as 
with base_query as(
select 
	f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    concat(c.first_name,' ', c.last_name) as customer_name,
    TIMESTAMPDIFF(year, c.birthdate, curdate() ) age
from fact_sales_gold f 
left join dim_customers_gold c
on c.customer_key = f.customer_key  
where f.order_date is not null)

, customer_aggregation as (
select 
	customer_key,
    customer_number,
    customer_name,
    age,
    count(distinct order_number ) as total_order,
    sum(sales_amount) as total_sales,
    sum(quantity) as total_quantity ,
    count(distinct product_key)  as total_products,
    max(order_date) as last_order_date,
    PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM MAX(order_date)), EXTRACT(YEAR_MONTH FROM MIN(order_date))) AS lifespan
from base_query 
group by customer_key,
    customer_number,
    customer_name,
    age)

select
	customer_key,
    customer_number,
    customer_name,
    age,
    case when age <20 then 'Below 20'
		 when age between 20 and 29 then '20-29'
         when age between 30 and 39 then '30-39'
         when age between 40 and 49 then '40-49'
         else '50 and above'
     end age_group,    
    case when lifespan >= 12 and total_sales > 5000 then 'VIP'
			 when lifespan >= 12 and total_sales <= 5000 then 'Regular'
			 else 'New'
     end customer_segment,  
	last_order_date,
    TIMESTAMPDIFF(MONTH, last_order_date, CURDATE()) AS recency,
    total_order,
	total_sales,
	total_quantity ,
	total_products,
    lifespan,
    case when total_sales =0 then 0
		 else round(total_sales/total_order,2) 
	end as avg_order_vales,
    case when lifespan = 0 then total_sales 
		 else round(total_sales / lifespan,2)
     end avg_monthly_sales     
from customer_aggregation;

select * from customer_report_gold	

		
    







