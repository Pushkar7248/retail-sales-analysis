--Sample records
SELECT * FROM public.sales LIMIT 10;


--Total records
SELECT COUNT(*) AS total_records FROM public.sales;


--Date range
SELECT MIN(order_date) AS first_order_date, MAX(order_date) AS last_order_date
FROM public.sales;


--Overall KPIs
SELECT COUNT(*) AS total_records, ROUND(SUM(total), 2) AS total_revenue,
       ROUND(AVG(total), 2) AS average_sale, SUM(quantity) AS total_units_sold
FROM public.sales;


--Missing-value checks
SELECT
 COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
 COUNT(*) FILTER (WHERE order_date IS NULL) AS missing_order_date,
 COUNT(*) FILTER (WHERE product IS NULL) AS missing_product,
 COUNT(*) FILTER (WHERE quantity IS NULL) AS missing_quantity,
 COUNT(*) FILTER (WHERE unit_price IS NULL) AS missing_unit_price,
 COUNT(*) FILTER (WHERE total IS NULL) AS missing_total,
 COUNT(*) FILTER (WHERE region IS NULL) AS missing_region,
 COUNT(*) FILTER (WHERE salesperson IS NULL) AS missing_salesperson
FROM public.sales;


--Duplicate order IDs
SELECT order_id, COUNT(*) AS occurrences
FROM public.sales GROUP BY order_id HAVING COUNT(*) > 1;


--Regional sales performance
SELECT region, COUNT(*) AS total_records, ROUND(SUM(total), 2) AS total_revenue,
       ROUND(AVG(total), 2) AS average_sale
FROM public.sales GROUP BY region ORDER BY total_revenue DESC;


--Product performance
SELECT product, SUM(quantity) AS units_sold, ROUND(SUM(total), 2) AS total_revenue,
       ROUND(AVG(total), 2) AS average_sale
FROM public.sales GROUP BY product ORDER BY total_revenue DESC;


--Salesperson performance
SELECT salesperson, COUNT(*) AS total_records, ROUND(SUM(total), 2) AS total_revenue,
       ROUND(AVG(total), 2) AS average_sale
FROM public.sales GROUP BY salesperson ORDER BY total_revenue DESC;


--Monthly sales summary
SELECT DATE_TRUNC('month', order_date)::date AS sales_month, COUNT(*) AS total_records,
       ROUND(SUM(total), 2) AS monthly_revenue, ROUND(AVG(total), 2) AS average_sale
FROM public.sales GROUP BY DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date);


--Top 10 sales transactions
SELECT order_id, order_date, product, region, quantity, ROUND(total, 2) AS sale_amount
FROM public.sales ORDER BY total DESC LIMIT 10;


--Rank regions by revenue
WITH regional_sales AS (
 SELECT region, SUM(total) AS total_revenue FROM public.sales GROUP BY region
)
SELECT region, ROUND(total_revenue, 2) AS total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM regional_sales ORDER BY revenue_rank;


--Regional revenue contribution
SELECT region, ROUND(SUM(total), 2) AS total_revenue,
       ROUND(100.0 * SUM(total) / SUM(SUM(total)) OVER (), 2) AS revenue_percentage
FROM public.sales GROUP BY region ORDER BY total_revenue DESC;


--Exportable regional revenue report
SELECT region, COUNT(*) AS total_records, ROUND(SUM(total), 2) AS total_revenue,
       ROUND(100.0 * SUM(total) / SUM(SUM(total)) OVER (), 2) AS revenue_percentage
FROM public.sales GROUP BY region ORDER BY total_revenue DESC;


--Top 5 sales transactions
SELECT order_id, order_date, product, region, quantity, ROUND(total, 2) AS sale_amount
FROM public.sales ORDER BY total DESC LIMIT 5;


--Top 5 salespeople by revenue
SELECT salesperson, COUNT(*) AS total_records, ROUND(SUM(total), 2) AS total_revenue,
       ROUND(AVG(total), 2) AS average_sale
FROM public.sales GROUP BY salesperson ORDER BY total_revenue DESC LIMIT 5;


--Salesperson revenue contribution
WITH salesperson_sales AS (
 SELECT salesperson, SUM(total) AS total_revenue
 FROM public.sales GROUP BY salesperson
)
SELECT salesperson, ROUND(total_revenue, 2) AS total_revenue,
       ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 2) AS revenue_percentage
FROM salesperson_sales ORDER BY total_revenue DESC;


--Top-revenue product in each region
WITH regional_product_sales AS (
 SELECT region, product, SUM(total) AS total_revenue
 FROM public.sales GROUP BY region, product
), ranked_products AS (
 SELECT region, product, total_revenue,
        RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS product_rank
 FROM regional_product_sales
)
SELECT region, product, ROUND(total_revenue, 2) AS total_revenue
FROM ranked_products WHERE product_rank = 1 ORDER BY region;


--Top product's share of regional revenue
WITH regional_product_sales AS (
 SELECT region, product, SUM(total) AS product_revenue
 FROM public.sales GROUP BY region, product
), ranked_products AS (
 SELECT region, product, product_revenue,
        RANK() OVER (PARTITION BY region ORDER BY product_revenue DESC) AS product_rank
 FROM regional_product_sales
), regional_totals AS (
 SELECT region, SUM(total) AS regional_revenue
 FROM public.sales GROUP BY region
)
SELECT p.region, p.product, ROUND(p.product_revenue, 2) AS product_revenue,
       ROUND(r.regional_revenue, 2) AS regional_revenue,
       ROUND(100.0 * p.product_revenue / r.regional_revenue, 2) AS regional_revenue_share
FROM ranked_products p JOIN regional_totals r ON r.region = p.region
WHERE p.product_rank = 1 ORDER BY regional_revenue_share DESC;


--Products ranked by average sale
SELECT product, COUNT(*) AS total_records, SUM(quantity) AS units_sold,
       ROUND(AVG(total), 2) AS average_sale, ROUND(SUM(total), 2) AS total_revenue
FROM public.sales GROUP BY product ORDER BY average_sale DESC;


--Categorize sales by transaction value
SELECT order_id, order_date, product, region, total,
       CASE WHEN total >= 1000 THEN 'High Value'
            WHEN total >= 500 THEN 'Medium Value'
            ELSE 'Low Value' END AS sale_value_category
FROM public.sales ORDER BY total DESC;


--Summary by sales value category
WITH categorized_sales AS (
 SELECT total, CASE WHEN total >= 1000 THEN 'High Value'
                    WHEN total >= 500 THEN 'Medium Value'
                    ELSE 'Low Value' END AS sale_value_category
 FROM public.sales
)
SELECT sale_value_category, COUNT(*) AS total_records, ROUND(SUM(total), 2) AS total_revenue,
       ROUND(AVG(total), 2) AS average_sale,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS record_percentage,
       ROUND(100.0 * SUM(total) / SUM(SUM(total)) OVER (), 2) AS revenue_percentage
FROM categorized_sales GROUP BY sale_value_category ORDER BY total_revenue DESC;


--Month-over-month revenue growth
WITH monthly_sales AS (
 SELECT DATE_TRUNC('month', order_date)::date AS sales_month, SUM(total) AS monthly_revenue
 FROM public.sales GROUP BY DATE_TRUNC('month', order_date)
), monthly_comparison AS (
 SELECT sales_month, monthly_revenue,
        LAG(monthly_revenue) OVER (ORDER BY sales_month) AS previous_month_revenue
 FROM monthly_sales
)
SELECT TO_CHAR(sales_month, 'YYYY-MM') AS sales_month,
       ROUND(monthly_revenue, 2) AS monthly_revenue,
       ROUND(previous_month_revenue, 2) AS previous_month_revenue,
       ROUND(100.0 * (monthly_revenue - previous_month_revenue)
             / NULLIF(previous_month_revenue, 0), 2) AS month_over_month_growth_percentage
FROM monthly_comparison ORDER BY sales_month;


--Best sales month in each region
WITH regional_monthly_sales AS (
 SELECT region, DATE_TRUNC('month', order_date)::date AS sales_month, SUM(total) AS monthly_revenue
 FROM public.sales GROUP BY region, DATE_TRUNC('month', order_date)
), ranked_months AS (
 SELECT region, sales_month, monthly_revenue,
        RANK() OVER (PARTITION BY region ORDER BY monthly_revenue DESC) AS month_rank
 FROM regional_monthly_sales
)
SELECT region, TO_CHAR(sales_month, 'Mon YYYY') AS best_sales_month,
       ROUND(monthly_revenue, 2) AS monthly_revenue
FROM ranked_months WHERE month_rank = 1 ORDER BY monthly_revenue DESC;


--Final regional performance summary
WITH regional_summary AS (
 SELECT region, COUNT(*) AS total_records, SUM(total) AS total_revenue, AVG(total) AS average_sale
 FROM public.sales GROUP BY region
), regional_rankings AS (
 SELECT region, total_records, total_revenue, average_sale,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        100.0 * total_revenue / SUM(total_revenue) OVER () AS revenue_percentage
 FROM regional_summary
)
SELECT region, total_records, ROUND(total_revenue, 2) AS total_revenue,
       ROUND(average_sale, 2) AS average_sale, revenue_rank,
       ROUND(revenue_percentage, 2) AS revenue_percentage
FROM regional_rankings ORDER BY revenue_rank;


