/*
===================================================================================================
A)Analyze Sales Performance Over Time
==================================================================================================
*/

---i)Changes Over Years

SELECT
	YEAR(order_date) AS order_year,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

---ii)Changes Over months

SELECT
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) as total_quantity
FROM [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date)

---iii)Changes Over months with customised Date Format using the function DATETRUNC

SELECT
	DATETRUNC(MONTH, order_date) AS order_month,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) as total_quantity
FROM [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date)

---iv)Changes Over months with customised Date Format using the function FORMAT

SELECT
	FORMAT(order_date, 'yyyy-MMM') AS order_month,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) as total_quantity
FROM [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')

/*
=====================================================================================
B)Cumulative Analysis
=====================================================================================
*/
---Calculate the total sales per month and the running total of sales overtime
---i)Calculate the running total of sales over months

SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales
FROM
(SELECT
	DATETRUNC(month,order_date) AS order_date,
	SUM(sales_amount) AS total_sales
FROM [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date))t

---ii)Calculate the running total of sales over months for each year separately(PARTITION BY YEAR)
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales
FROM
(SELECT
	DATETRUNC(month,order_date) AS order_date,
	SUM(sales_amount) AS total_sales
FROM [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date))t

---iii)Calculate the running total of sales year wise
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales
FROM
(SELECT
	DATETRUNC(YEAR,order_date) AS order_date,
	SUM(sales_amount) AS total_sales
FROM [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date))t

---iv)Calculate the moving average of price and total_sales year over years
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY order_date) AS moving_average
FROM
(SELECT
	DATETRUNC(YEAR,order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	AVG(price) AS avg_price
FROM [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date))t

/*
==============================================================================================
C) Performance Analysis- Comparing the current value to a target value:
===============================================================================================
*/
---Analyze the yearly performance of products by comparing each product's sales
---to both it's average sales performance and the previous year's sales
WITH yearly_product_sales AS(

SELECT
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_products] p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name)

SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) avg_sales,
current_sales-AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales-AVG(current_sales) OVER (PARTITION BY product_name)> 0 THEN 'above_avg'
WHEN current_sales-AVG(current_sales) OVER (PARTITION BY product_name)<0 THEN 'below_avg'
ELSE 'Avg'
END 'Avg_Change',
---Year-Over-Year Analysis
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales,
current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) diff_py,
CASE WHEN current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year)<0 THEN 'increase'
WHEN current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year)>0 THEN 'decrease'
ELSE 'no change'
END 'py_change'
FROM yearly_product_sales
ORDER BY product_name, order_year

/*
===============================================================================================
D) Part-to-Whole Analsysis/Proportional Analysis
===============================================================================================
*/
---Analyze how an individual part is performing compared to the
---overall, allowing us to understand which category has the greatest
---impact on the business.
---i) which categores contribute the most to overall sales?
---overall sales by product category
SELECT
p.category,
SUM(f.sales_amount) AS total_sales
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_products] p
ON p.product_key = f.product_key
GROUP BY category

--- g
WITH category_sales AS (
SELECT
category,
SUM(f.sales_amount) AS total_sales
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_products] p
ON p.product_key = f.product_key
GROUP BY category)

SELECT
category,
total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER() )*100,2),'%') AS percentage_of_total_sales
FROM category_sales

/*
===========================================================================================================
E)Data Segementation 
==========================================================================================================
*/
---Group the data bsed on a specific range
---Helps understand the correlation between two measures
---i) Segement products into cost ranges count how many products
----fall into each segement
WITH product_segements AS (
SELECT
	product_key,
	product_name,
	cost,
CASE WHEN cost<100 THEN 'Below 100'
	WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	WHEN cost BETWEEN 500 AND 1000 THEN '500-100'
	ELSE 'Above 1000'
END AS 'cost_range'
FROM [gold.dim_products])
SELECT
	cost_range,
	COUNT(product_key) AS total_product_sales
FROM product_segements
GROUP BY cost_range 
ORDER BY total_product_sales DESC

---ii) Group customers into three segements based on their spending behavior:
------VIP: at least 12 months of history but spending 5,000 or elss
------Regular: at least 12 months of history but spending 5,000 or less
------New: lifespan less than months.
------And find the total number of customers by each group


WITH customer_spending AS(
SELECT
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan 
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_customers] c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT
customer_key,
total_spending,
lifespan,
CASE WHEN lifespan>=12 AND total_spending>5000 THEN 'VIP'
	WHEN lifespan >=12 AND total_spending<= 5000 THEN 'Regular'
	ELSE 'New'
	END 'customer_segement'
FROM customer_spending

------And find the total number of customers by each group

WITH customer_spending AS(
SELECT
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan 
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_customers] c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT
customer_segment,
COUNT(customer_key) AS total_customer

FROM(
SELECT
customer_key,
CASE WHEN lifespan>=12 AND total_spending>5000 THEN 'VIP'
	WHEN lifespan >=12 AND total_spending<= 5000 THEN 'Regular'
	ELSE 'New'
	END 'customer_segment'
FROM customer_spending)t
GROUP BY customer_segment
ORDER BY total_customer DESC

/*
======================================================================================================================
Customer Report
======================================================================================================================
Purpose:
	-This report consolidates key customer metrics and behaviours
Highlights:
	1. Gather essential fields such as names, ages, and transaction details.
	2. Segements customer into categories(VIP, Regular, New) and age groups.
	3. Aggregates customer_level metrics
		-total orders
		-total sales
		-total quantity purchased
		-total products
		-lifespan-(in months)
	4. Calculates valuable KPIs:
		-recency(months since last order)
		-average order value
		-average monthly spend
*/

WITH base_query AS
/*
---------------------------------------------------------------
1) Bse Query: Retrieve core columns from tables
-----------------------------------------------------------------
*/
(SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
c.first_name,
c.last_name,
DATEDIFF(year, c.birthdate,GETDATE()) AS age,
CONCAT(c.first_name, ' ',c.last_name) AS customer_name
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_customers] c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)
/*
---------------------------------------------------------------
1) Customer Aggregation: summarises key matrics at the customer level
-----------------------------------------------------------------
*/
, customer_aggregation AS(
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE
	WHEN age<20 THEN 'under 20'
	WHEN age BETWEEN 20 AND 29 THEN '20-29'
	WHEN age BETWEEN 30 AND 39 THEN '30-39'
	WHEN age BETWEEN 40 AND 49 THEN '40-49'
ELSE '50 and above'
END AS age_group,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(product_key) AS total_products,
MAX(order_date) AS last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
customer_key,
customer_number,
customer_name,
age)

SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	WHEN lifespan>=12 AND total_sales>=5000 THEN 'VIP'
	WHEN lifespan>=12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END AS cutomer_segement,
total_orders,
total_sales,
total_quantity,
total_products,
last_order_date,
lifespan
FROM customer_aggregation

/*
-------------------------------------------------------------------------------------------------------------
4. Calculates valuable KPIs:
		-recency(months since last order)
		-average order value
		-average monthly spend
--------------------------------------------------------------------------------------------------------------
*/
CREATE VIEW dbo.report_customers AS

WITH base_query AS
/*
---------------------------------------------------------------
1) Base Query: Retrieve core columns from tables
-----------------------------------------------------------------
*/
(SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
c.first_name,
c.last_name,
DATEDIFF(year, c.birthdate,GETDATE()) AS age,
CONCAT(c.first_name, ' ',c.last_name) AS customer_name
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_customers] c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)
/*
---------------------------------------------------------------
1) Customer Aggregation: summarises key matrics at the customer level
-----------------------------------------------------------------
*/
, customer_aggregation AS(
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE
	WHEN age<20 THEN 'under 20'
	WHEN age BETWEEN 20 AND 29 THEN '20-29'
	WHEN age BETWEEN 30 AND 39 THEN '30-39'
	WHEN age BETWEEN 40 AND 49 THEN '40-49'
ELSE '50 and above'
END AS age_group,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(product_key) AS total_products,
MAX(order_date) AS last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
customer_key,
customer_number,
customer_name,
age)

/* 
---------------------------------------------------------------------------------------------------------------------------
Final Query
----------------------------------------------------------------------------------------------------------------------------
*/
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	WHEN lifespan>=12 AND total_sales>=5000 THEN 'VIP'
	WHEN lifespan>=12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END AS cutomer_segement,
DATEDIFF(MONTH,last_order_date,GETDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products,
last_order_date,
lifespan,
---compute average order value(AOV)
CASE WHEN total_sales =0 THEN 0
	ELSE total_sales/total_orders
	END AS avg_order_value,
---compute average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
	ELSE total_sales/lifespan
END AS avg_monthly_spend
FROM customer_aggregation