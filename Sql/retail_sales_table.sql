--Create Sales Table
CREATE TABLE sales (
order_id INTEGER PRIMARY KEY,
order_date DATE,
product VARCHAR(100),
quantity INTEGER,
unit_price NUMERIC(10,2),
total NUMERIC(12,2),
region VARCHAR(50),
salesperson VARCHAR(100)
);

select * from sales


--Fix the Order ID Column
ALTER TABLE public.sales
ALTER COLUMN order_id TYPE VARCHAR(20);


