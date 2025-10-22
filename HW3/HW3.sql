use HW3;

-- set the primary and foreign keys for each table

ALTER TABLE merchants
ADD PRIMARY KEY (mid);

ALTER TABLE products
ADD PRIMARY KEY (pid);

ALTER TABLE orders
ADD PRIMARY KEY (oid);

ALTER TABLE customers
ADD PRIMARY KEY (cid);

ALTER TABLE sell
ADD FOREIGN KEY (mid) REFERENCES merchants(mid);
ALTER TABLE sell
ADD FOREIGN KEY (pid) REFERENCES products(pid);

ALTER TABLE contain
ADD FOREIGN KEY (oid) REFERENCES orders(oid);
ALTER TABLE contain
ADD FOREIGN KEY (pid) REFERENCES products(pid);

ALTER TABLE place
ADD FOREIGN KEY (cid) REFERENCES customers(cid);
ALTER TABLE place
ADD FOREIGN KEY (oid) REFERENCES orders(oid);

-- add constraints
ALTER TABLE products
ADD CONSTRAINT check_name
CHECK (name in ('Printer', 
    'Ethernet Adapter', 
    'Desktop', 
    'Hard Drive', 
    'Laptop', 
    'Router', 
    'Network Card', 
    'Super Drive', 
    'Monitor'
));

ALTER TABLE products
ADD CONSTRAINT check_category
CHECK (category in ('Peripheral', 'Networking', 'Computer'));

ALTER TABLE sell
ADD CONSTRAINT check_price
CHECK (price >= 0 AND price <= 100000);

ALTER TABLE sell
ADD CONSTRAINT check_quantity
CHECK (quantity_available >= 0 AND quantity_available <= 1000);

ALTER TABLE orders
ADD CONSTRAINT check_shipping
CHECK (shipping_method IN ('UPS', 'FedEx', 'USPS'));

ALTER TABLE orders
ADD CONSTRAINT check_shipping_cost
CHECK (shipping_cost >= 0 AND shipping_cost <= 500); 

ALTER TABLE place
MODIFY COLUMN order_date DATE NOT NULL;
ALTER TABLE place
ADD CONSTRAINT check_date
CHECK (order_date BETWEEN '2010-01-01' AND '2099-01-01');

-- 1. Name of sellers and products that have availability = 0
-- goes to table sell, joins with merhchants, joins with products and then check the quantiity availiable to be 0 
SELECT m.name, p.name
FROM sell
INNER JOIN merchants m
USING(mid)
INNER JOIN products p
USING(pid)
WHERE quantity_available = 0;

-- 2. List names and descriptions of products that are not sold
-- goes to products table, joins with sell using pid, then checks the quantity avaiable to be greaters than 0
SELECT p.name, p.description, s.quantity_available
FROM products p
INNER JOIN sell s 
USING (pid)
WHERE quantity_available > 0;

-- 3. How many customers bought SATA drives but not any routers?
-- select a distinct count of customers, from customers table, join place on cid, join contain on oid
SELECT DISTINCT COUNT(c.cid)
FROM customers c
INNER JOIN place p ON p.cid = c.cid
INNER JOIN contain co ON co.oid = p.oid
WHERE co.pid IN (4,5)
-- to ensure there are no customers of routers, select distinct count of cids, from customers table, 
-- join place on cid, join contain on oid, products on pid, then check if the product is a router
EXCEPT 
SELECT DISTINCT COUNT(c.cid)
FROM customers c
INNER JOIN place p ON p.cid = c.cid
INNER JOIN contain co ON co.oid = p.oid
INNER JOIN products pr ON pr.pid = co.pid
WHERE pr.name = 'Router';

-- 4. HP has a 20% sale on all its products.
-- change the prices with the update keyword
UPDATE sell
SET price = price - (price*0.20)
WHERE mid = 3;
-- display all of the info for HP products
SELECT *
FROM sell
WHERE mid = 3;

-- 5. What did Uriel Whitney order? (retrieve product name and prices)
SELECT DISTINCT pr.name AS product_name, -- show the products, show all the prices for the products 
	MIN(s.price) AS min_price,
	MAX(s.price) AS max_price,
    AVG(s.price) AS average_price
FROM place p -- from the products table, join customers, orders, contain, products, and sell
INNER JOIN customers c ON c.cid = p.cid
INNER JOIN orders o ON o.oid = p.oid
INNER JOIN contain co ON co.oid = o.oid
INNER JOIN products pr ON pr.pid = co.pid
INNER JOIN sell s ON s.pid = pr.pid
WHERE c.fullname = 'Uriel Whitney' -- check the customer name
GROUP BY pr.pid, pr.name; -- organize by pid and name


-- 6. Annual total sales for each company (sort the results along the company and the year attributes)
SELECT m.name AS company_name,  -- display the company name, the year from order date, and the price of all products as sales
	EXTRACT(YEAR FROM p.order_date) AS year, 
    SUM(s.price) AS sales
FROM merchants m  -- from the merchants table join sell, contain, orders, place
INNER JOIN sell s ON s.mid = m.mid
INNER JOIN contain co ON co.pid = s.pid
INNER JOIN orders o ON o.oid = co.oid
INNER JOIN place p ON p.oid = o.oid
WHERE order_date BETWEEN '2020-01-01' AND '2020-12-31' -- look between the proper date range for the 2020 year
GROUP BY m.mid, m.name, EXTRACT(YEAR FROM p.order_date)
ORDER BY m.name, year;

-- 7. Which company had the highest annual revenue and in what year 
SELECT m.name AS company_name, -- display the company name, their revenue, and the year it was the highest
		SUM(s.price) AS revenue, 
		EXTRACT(YEAR FROM p.order_date) AS year
FROM merchants m -- from merchants table join sell, contain, orders, place
INNER JOIN sell s ON s.mid = m.mid
INNER JOIN contain co ON co.pid = s.pid
INNER JOIN orders o ON o.oid = co.oid
INNER JOIN place p ON p.oid = o.oid
GROUP BY m.mid, m.name, EXTRACT(YEAR FROM p.order_date)
ORDER BY SUM(s.price) DESC -- order by the sum of prices descending so the highest is on top
LIMIT 1; --  limit 1 so the highest year is the only displayed


-- 8. On average, what was the cheapest shipping method ever used?
SELECT shipping_method, AVG(shipping_cost) AS average_cost -- display the shipping method and how much it costs
FROM orders 
GROUP BY shipping_method -- organize by the shipping method
ORDER BY AVG(shipping_cost) ASC -- order the average cost ascending so the cheapest average is on top
LIMIT 1; -- limit 1 so the only method displayed is the cheapest  on average

-- 9. What is the best sold ($) category for each company?
WITH category_sales AS ( -- create category sales variable
    SELECT m.mid, -- variable will give access to the the company name, the product's category, 
     -- 			total sales, and the ranking of the prices
        m.name AS company_name,
        p.category,
        SUM(s.price) AS total_sales,
        RANK() OVER (PARTITION BY m.mid ORDER BY SUM(s.price) DESC) AS ranking
    FROM merchants m
    INNER JOIN sell s ON s.mid = m.mid
    INNER JOIN products p ON p.pid = s.pid
    INNER JOIN contain co ON co.pid = p.pid
    INNER JOIN orders o ON o.oid = co.oid
    GROUP BY m.mid, m.name, p.category
)
SELECT company_name, category, total_sales
FROM category_sales
WHERE ranking = 1 -- display the company, category and total sales where the ranking of sales is equal to 1
ORDER BY company_name;

-- 10. For each company find out which customers have spent the most and the least amounts

-- create variable of the customer spending for each company
WITH customer_spending AS( -- create customer spending variable
	SELECT m.mid,  -- display the company, customer name and total spent, then the rank of the how much they have spent
			m.name AS company,
			c.fullname AS customer_name,
            SUM(s.price) AS total_spent,
            RANK() OVER(PARTITION BY m.mid ORDER BY SUM(s.price) DESC) AS spend_rank_desc,
            RANK() OVER(PARTITION BY m.mid ORDER BY SUM(s.price) ASC) AS spend_rank_asc
	FROM merchants m
    Inner JOIN sell s ON s.mid = m.mid
    INNER JOIN contain co ON co.pid = s.pid
    INNER JOIN place p ON p.oid = co.oid
    INNER JOIN customers c ON c.cid = p.cid
    GROUP BY m.mid, m.name, c.fullname
),
highest_spender AS( -- variable displays info if the they rank the highest on variable where rank 1 
-- 						is associated with higher customer spending
	SELECT mid, company, customer_name, total_spent
    FROM customer_spending
    WHERE spend_rank_desc = 1
    ),
lowest_spender AS( -- variable displays info if the they rank the lowest on variable where rank 1 
-- 						is associated with lower customer spending
	SELECT mid, company, customer_name, total_spent
    FROM customer_spending
    WHERE spend_rank_asc = 1)

SELECT h.company AS company, -- display neccessary info from both high and low variables
		h.customer_name AS highest_spender,
        h.total_spent AS highest_spent,
        l.customer_name AS lowest_spender,
        l.total_spent AS lowest_spent
FROM highest_spender h
INNER JOIN lowest_spender l ON l.mid = h.mid
ORDER BY h.company;
