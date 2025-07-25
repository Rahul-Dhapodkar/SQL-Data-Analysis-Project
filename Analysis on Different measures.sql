#YOY CHANGE 
SELECT 
		year(order_date) as order_year,
		month(order_date) as order_month,
        sum(sales_amount) as total_sales,
        count(distinct customer_key) as total_customer,
        sum(quantity) as total_quantity
from fact_sales_gold 
where order_date is not NULL
group by order_year, order_month 
order by order_year, order_month ;

/*another way of writing it */
SELECT 
    DATE_FORMAT(order_date, '%Y-%m-01') AS order_datee,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customer,
    SUM(quantity) AS total_quantity
FROM fact_sales_gold 
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY DATE_FORMAT(order_date, '%Y-%m-01');

#CUMMULATIVE ANALYSIS 
#Calculate the total sales per month 
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (partition by Year(order_date) order BY order_date) AS running_total_sales,
    AVG(total_sales) OVER (partition by year(order_date) ORDER BY order_date) AS running_avg_sales

FROM (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m-01') AS order_date,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM fact_sales_gold
    WHERE order_date IS NOT NULL
    GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
    ORDER BY DATE_FORMAT(order_date, '%Y-%m-01')
) AS monthly_summary
WHERE order_date IS NOT NULL ;

/*analyze the yearly perpormance of the product by comparing 
their sales to both the avg sales performance of the product and the previous yeaar sales  */

with yearly_product_sales as(
		select
			year(f.order_date) as order_year,
            p.product_name,
            sum(f.sales_amount) as current_sales
        from fact_sales_gold f
        left join dim_products_gold p
        on f.product_key =p.product_key 
        where f.order_date is not null
        group by year(f.order_date),  p.product_name
)
select
	order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (partition by product_name)  AS avg_sales,
    current_sales - AVG(current_sales) OVER (partition by product_name) as diff_avg,
    CASE WHEN current_sales - AVG(current_sales) OVER (partition by product_name) > 0 then 'Above Avg'
		 WHEN current_sales - AVG(current_sales) OVER (partition by product_name) < 0 then 'Below Avg'
		 else 'Avg'
    end avg_change,
    LAG(current_sales)  OVER (partition by product_name order by order_year)py_sales,
    current_sales - LAG(current_sales)  OVER (partition by product_name order by order_year) as diff_py,
    case when current_sales - LAG(current_sales)  OVER (partition by product_name order by order_year) > 0 then 'Increase'
		 when current_sales - LAG(current_sales)  OVER (partition by product_name order by order_year) < 0 then 'Decrease'
         else 'No change'
    end py_chnage
from  yearly_product_sales
where order_year is not null
order by product_name, order_year  ;


# WHICH CATEGORY CONTRIBUTE THE MOST TO THE OVER ALL SALES
with category_sales as (
	select
		category,
        sum(f.sales_amount) total_sales 
	from fact_sales_gold f
	left join  dim_products_gold p
	on p.product_key = f.product_key 
	group by category
)
select
		category,
        total_sales,
        sum(total_sales) over() overall_sales,
        concat(round((cast(total_sales as float) / sum(total_sales) over())*100 ,2), '%') as percemtage_of_total
from   category_sales
order by total_sales desc ;  

# SEGMENT ANALYSIS
# segment products into cost range and count total no. products fall in that range 
with product_segment as(
select 
	product_key,
    product_name,
    cost,
    case when cost < 100 then 'Below 100'
		 when cost <500 then '100-500'
         when cost <1000 then '500-1000'
         else 'Above 1000'
         end cost_range 
from dim_products_gold )

select 
	cost_range,
    count(product_key) as total_products
from product_segment
group by cost_range
order by total_products desc;
    
/*Group customers into three segments based on their spending behavior:
    - VIP: Customers with at least 12 months of history and spending more than €5,000.
    - Regular: Customers with at least 12 months of history but spending €5,000 or less.
    - New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/

with customer_segmentation as(
select 
	d.customer_key,
    sum(f.sales_amount) as total_sales,
    f.order_date,
    min(order_date) as first_order,
    max(order_date) as last_order,
    PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM MAX(order_date)), EXTRACT(YEAR_MONTH FROM MIN(order_date))) AS lifespan 
from fact_sales_gold f 
left join dim_customers_gold d
on f.customer_key = d.customer_key
where order_date is not null 
group by d.customer_key)

select 
	customer_segment,
	count(customer_key) as total_customers
from (
	select
		customer_key,
		case when lifespan >= 12 and total_sales > 5000 then 'VIP'
			 when lifespan >= 12 and total_sales <= 5000 then 'Regular'
			 else 'New'
		end customer_segment 
	from customer_segmentation ) as cs    
group by customer_segment 
order by total_customers desc 






		






