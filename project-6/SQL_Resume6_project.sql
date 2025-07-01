 select * from dim_customer WHERE customer="Atliq exclusive";
select * from dim_product where product='AQ Master wired x1 Ms';
select * from fact_gross_price;
select * from fact_manufacturing_cost;
select * from fact_pre_invoice_deductions;
select * from fact_sales_monthly where year(date)=2019;
select * from fact_gross_price;
use gdb023
-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region
select market 
from dim_customer
where customer='Atliq Exclusive' and region='APAC'

-- -2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg
use gdb023;
WITH unq_2021 AS (
    SELECT DISTINCT product_code
    FROM fact_sales_monthly
    WHERE fiscal_year = 2021
),
unq_prod_2021 AS (
    SELECT COUNT(DISTINCT product_code) AS cnt
    FROM fact_sales_monthly
    WHERE fiscal_year = 2021
),
unq_prod_2020 AS (
    SELECT COUNT(DISTINCT product_code) AS cnt
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
)

SELECT 
    u2.cnt AS unique_products_2020,
    u1.cnt AS unique_products_2021,
   round( ((u1.cnt - u2.cnt) * 100.0 / u2.cnt),2) AS percentage_chg
FROM 
    unq_prod_2021 u1,
    unq_prod_2020 u2;

-- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select segment,count(distinct product_code) as product_count from dim_product
group by segment
order by product_count desc


-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference
with p_counts as(
select count(distinct fsm.product_code) as product_count,dm.segment, max(1 )as num 
 from fact_sales_monthly fsm join dim_product dm on  fsm.product_code=dm.product_code
where fsm.fiscal_year =2020
group by dm.segment
union all
select count(distinct fsm.product_code) as product_count,dm.segment,max(2 )as num  
 from fact_sales_monthly fsm join dim_product dm on  fsm.product_code=dm.product_code
where fsm.fiscal_year =2021
group by dm.segment)

    SELECT 
        segment,
        max(cASE WHEN num = 1 THEN product_count ELSE 0 END) AS product_count_2020,
        max(CASE WHEN num = 2 THEN product_count ELSE 0 END) AS product_count_2021
    FROM p_counts
   group by segment
select * from dim_product;
-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost
use gdb023
with high_manufacturing_cost as(
select product_code,manufacturing_cost,row_number()over(order by manufacturing_cost desc) as max_cost from fact_manufacturing_cost
),lowest_cost as(select product_code,manufacturing_cost,row_number()over(order by manufacturing_cost ) as min_cost from fact_manufacturing_cost
),high_and_low_prod as(

select product_code,manufacturing_cost from high_manufacturing_cost where max_cost=1
union all
select product_code,manufacturing_cost from lowest_cost where min_cost=1)

select hl.*,dm.product
from high_and_low_prod hl join dim_product dm on
hl.product_code=dm.product_code
-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage


select ad.customer_code,dm.customer,avg(pre_invoice_discount_pct) as average_discount_percentage
from fact_pre_invoice_deductions ad
join dim_customer dm on dm.customer_code=ad.customer_code and dm.market="India"
where ad.fiscal_year=2021
group by  ad.customer_code,dm.customer 
order by average_discount_percentage desc limit 5


-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount
use gdb023
with gr_sale as(
select fs.date,fs.sold_quantity* fg.gross_price  as Gross_sales_amount from fact_gross_price fg
join fact_sales_monthly fs on fs.product_code=fg.product_code join dim_customer c 
on fs.customer_code=c.customer_code  WHERE c.customer="Atliq exclusive")

select month(date)as month_sales ,year(date) as year_sales ,sum(Gross_sales_amount)  as Gross_sales_amount 
from gr_sale
group by month(date),year(date)
order by year(date),month(date)

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity
SELECT 
    CASE 
        WHEN MONTH(date) IN (8, 7, 6) THEN 'Q4'
        WHEN MONTH(date) IN (4, 5, 3) THEN 'Q3'
        WHEN MONTH(date) IN (11, 10, 9) THEN 'Q1'
        WHEN MONTH(date) IN (2, 1, 12) THEN 'Q2'
    END AS Quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year=2020
GROUP BY Quarter
ORDER BY Quarter
select * from fact_sales_monthly

-- 9.Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage
select * from fact_sales_monthly where fiscal_year=2021;
select * from fact_gross_price;
select * from dim_customer
with cte as(
select    dm.channel , sum(fsm.sold_quantity*fg.gross_price) as gross_sales_mln
from fact_sales_monthly fsm join fact_gross_price fg on 
fsm.product_code=fg.product_code 
join dim_customer dm  on dm.customer_code=fsm.customer_code
where fsm.fiscal_year=2021
group by dm.channel )

  select channel,
  round(gross_sales_mln/1000000,2) AS gross_sales_in_millions,
  round(gross_sales_mln/(sum(gross_sales_mln) OVER())*100,2) AS percentage 
FROM cte ;
     


-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order


with total_product_sold as(
select product_code,sum(sold_quantity) as total_qty_sold from fact_sales_monthly
where fiscal_year=2021
group by product_code
),rank_order as(
select  tp.product_code,dp.division,tp.total_qty_sold, rank()over(partition by dp.division  order by tp.total_qty_sold desc ) as rn from dim_product dp 
join total_product_sold tp on tp.product_code=dp.product_code)

select division,product_code,total_qty_sold,rn
from rank_order
where rn<=3
