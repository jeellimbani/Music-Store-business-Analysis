/*
==================================================
        MUSIC STORE BUSINESS ANALYSIS
==================================================

Portfolio SQL Project

Prepared by:
Jeel Limbani

Database:
Chinook Music Store Database

Tools:
PostgreSQL
PgAdmin
VS Code

==================================================
*/


/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */

SELECT title, last_name, first_name 
FROM employee
ORDER BY levels DESC
LIMIT 1;


/* Q2: Which countries have the most Invoices? */

SELECT COUNT(*) AS c, billing_country 
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;


/* Q3: What are top 3 values of total invoice? */

SELECT total 
FROM invoice
ORDER BY total DESC
LIMIT 3;


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT billing_city,SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total_spending DESC
LIMIT 1;




/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/*Method 1 */

SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoiceline ON invoice.invoice_id = invoiceline.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name = 'Rock'
)
ORDER BY email;


/* Method 2 */

SELECT DISTINCT email AS Email,first_name AS FirstName, last_name AS LastName, genre.name AS Name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoiceline ON invoiceline.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoiceline.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name = 'Rock'
ORDER BY email;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name = 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name,milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;




/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1


/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;




/*
=========================================================
        QUESTION SET 4 - BUSINESS ANALYSIS
=========================================================

These additional questions extend the original
Music Store Analysis project by focusing on
business insights and advanced PostgreSQL concepts.

=========================================================
*/


/* Q12: Find the top 5 customers by total spending. */

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 5;


/* Q13: Show monthly revenue trend. */



SELECT
    DATE_TRUNC('month', invoice_date) AS month,
    SUM(total) AS monthly_revenue
FROM invoice
GROUP BY month
ORDER BY month;


/* Q14: Revenue generated by each music genre. */

SELECT
    g.name AS genre,
    SUM(il.unit_price * il.quantity) AS revenue
FROM invoice_line il
JOIN track t
ON il.track_id = t.track_id
JOIN genre g
ON t.genre_id = g.genre_id
GROUP BY g.genre_id, g.name
ORDER BY revenue DESC;


/* Q15: Revenue generated by each artist. */

SELECT
    a.artist_id,
    a.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS revenue
FROM invoice_line il
JOIN track t
ON il.track_id = t.track_id
JOIN album al
ON t.album_id = al.album_id
JOIN artist a
ON al.artist_id = a.artist_id
GROUP BY a.artist_id, a.name
ORDER BY revenue DESC;






/*
=========================================================
        QUESTION SET 5 - ADVANCED BUSINESS ANALYSIS
=========================================================
*/


/* Q16: Top city by revenue in each country */

WITH city_sales AS
(
    SELECT
        billing_country,
        billing_city,
        SUM(total) AS revenue,
        DENSE_RANK() OVER(
            PARTITION BY billing_country
            ORDER BY SUM(total) DESC
        ) AS city_rank
    FROM invoice
    GROUP BY billing_country,billing_city
)

SELECT *
FROM city_sales
WHERE city_rank = 1
ORDER BY billing_country;




/* Q17: Revenue contribution by country */

SELECT
    billing_country,
    SUM(total) AS revenue,
    ROUND(
        SUM(total)*100/
        (SELECT SUM(total) FROM invoice),
        2
    ) AS revenue_percentage
FROM invoice
GROUP BY billing_country
ORDER BY revenue DESC;


/* Q18: Year over year revenue growth */

WITH yearly_sales AS
(
    SELECT
        EXTRACT(YEAR FROM invoice_date) AS sales_year,
        SUM(total) AS revenue
    FROM invoice
    GROUP BY EXTRACT(YEAR FROM invoice_date)
)

SELECT
    sales_year,
    revenue,
    LAG(revenue) OVER(ORDER BY sales_year) AS previous_year,
    revenue -
    LAG(revenue) OVER(ORDER BY sales_year)
    AS growth
FROM yearly_sales;


/* Q19: Customer segmentation */

SELECT
    customer_id,
    first_name,
    last_name,
    total_spent,
    CASE
        WHEN total_spent >= 40 THEN 'Premium'
        WHEN total_spent >= 20 THEN 'Gold'
        ELSE 'Regular'
    END AS customer_category
FROM
(
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(i.total) AS total_spent
    FROM customer c
    JOIN invoice i
    ON c.customer_id = i.customer_id
    GROUP BY c.customer_id,c.first_name,c.last_name
) t
ORDER BY total_spent DESC;


/* Q20: Handle NULL company names */

SELECT
    customer_id,
    first_name,
    last_name,
    COALESCE(company,'Individual Customer') AS company_name
FROM customer
ORDER BY customer_id;


/*
==================================================
BUSINESS INSIGHTS & RECOMMENDATIONS
==================================================

1. Highest Revenue Country

Observation:
The country generating the highest revenue is the
store's strongest market.

Recommendation:
Increase marketing campaigns and customer retention
activities in this region.

--------------------------------------------------

2. Most Popular Music Genre

Observation:
Certain genres generate significantly higher sales.

Recommendation:
Expand the music catalog and promotional activities
for top-performing genres to maximize revenue.

--------------------------------------------------

3. High-Value Customers

Observation:
A small group of customers contributes a significant
portion of overall revenue.

Recommendation:
Introduce loyalty programs and personalized offers
to improve customer retention and increase repeat
purchases.

==================================================
*/


/*
==================================================
PROJECT CONCLUSION
==================================================

This project analyzed the Music Store database
using PostgreSQL to understand customer behavior,
sales trends, and music preferences.

The analysis identified top customers, profitable
genres, high-performing artists, and key revenue
markets while applying various SQL concepts such
as joins, CTEs, subqueries, and window functions.

The findings can support business decisions related
to marketing, customer retention, and sales growth.

==================================================
*/

