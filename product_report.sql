/*
===============================================================================
Product Report
===============================================================================

Purpose:
 - This report consolidates key product metrics and behaviors.

Highlights:
1. Gathers essential fields such as product name, category, subcategory, and cost.
2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
3. Aggregates product-level metrics:
   - total orders
   - total sales
   - total quantity sold
   - total customers (unique)
   - lifespan (in months)
4. Calculates valuable KPIs:
   - recency (months since last sale)
   - average order revenue (AOR)
   - average monthly revenue
===============================================================================
*/

with base_query as (
select 
	f.order_number,
    f.order_date,
    f.customer_key,
    f.sales_amount,
    f.quantity,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
from fact_sales_gold f 
left join dim_products_gold p 
on f.product_key = p.product_key
where order_date is not null ),

product_aggregaton as (
select 
	product_key,
    product_name,
    category,
    subcategory,
    cost,
    PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM MAX(order_date)), EXTRACT(YEAR_MONTH FROM MIN(order_date))) AS lifespan,
    max(order_date) as last_sale_date,
    count(distinct order_number ) as total_order,
    count(distinct customer_key ) as total_customer,
    sum(sales_amount) as total_sales,
    sum(quantity) as total_quantity ,
    round(avg(cast(sales_amount as float)/ NULLIF(quantity,0) ),1) as avg_selling_price
from base_query
group by product_key,
    product_name,
    category,
    subcategory,
    cost    
)
 select
	product_key,
    product_name,
    category,
    subcategory,
    cost, 
    last_sale_date,
    TIMESTAMPDIFF(MONTH, last_sale_date, CURDATE()) AS recency_in_months,
    case
		when total_sales > 5000 then 'High Performance'
        when total_sales <= 5000 then 'Mid Range'
        else 'Low Performance'
	end as product_segment ,
	lifespan,
    total_order,
    total_sales,
    total_quantity ,
    total_customer,
    avg_selling_price,
    case
		when total_order=0 then 0
        else round(total_sales / total_order,2)
        end as avg_order_revenue,
	case
		 when lifespan =0 then total_sales 
         else round(total_sales/ lifespan,2)
		 end as avg_monthly_revenue 
 from  product_aggregaton;         
        





















