##Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC regiON.
SELECT DISTINCT( market) FROM gdb023.dim_customer WHERE customer='Atliq Exclusive' and region='APAC';

##What is the percentage of unique product increASe in 2021 vs. 2020? 
##The final output cONtains these fields, unique_products_2020 unique_products_2021 percentage_chg

WITH 
    CTE1 AS(SELECT  count(DISTINCT(P.product_code)) AS Product_count,P.fiscal_year AS fiscal_year
            FROM gdb023.fact_sales_monthly  P 
			GROUP BY P.fiscal_year  )
Select a.Product_count AS unique_prod_2020,b.Product_count AS unique_prod_2021,(b.Product_count-a.Product_count) as Newly_introduced_product,
round(100.0*((b.Product_count-a.Product_count ) /a.Product_count),2)  AS percentage_chg FROM CTE1  AS a 
LEFT JOIN CTE1 AS b ON a.fiscal_year+1=b.fiscal_year  LIMIT 1;



##Provide a report WITH all the unique product counts for each segment and sort them in descending order of product counts.
##The final output cONtains 2 fields, segment product_count

SELECT P.segment ,count(DISTINCT(P.product_code)) AS Product_count FROM gdb023.dim_product P
GROUP BY P.segment ORDER BY Product_count Desc;

##Follow-up: Which segment had the most increASe in unique products in 2021 vs 2020?
##The final output contains these fields, segment product_count_2020 product_count_2021, difference .

WITH 
    CTE1 AS(SELECT P.segment  ,count(DISTINCT(P.product_code)) AS Prod_count1,G.fiscal_year FROM gdb023.dim_product P   RIGHT  JOIN 
    gdb023.fact_sales_mONthly  G  ON P.product_code=G.product_code WHERE G.fiscal_year= 2020 GROUP BY P.segment  order by P.segment Desc),

    CTE2 AS(SELECT P.segment  ,count(DISTINCT(P.product_code)) AS Prod_count2,G.fiscal_year FROM gdb023.dim_product P RIGHT JOIN 
	gdb023.fact_sales_mONthly  G  ON P.product_code=G.product_code WHERE G.fiscal_year= 2021 GROUP BY P.segment  ORDER BY P.segment Desc)
SELECT CTE1.segment,Prod_count1 AS products_count_2020,Prod_count2 AS products_count_2021 ,
round((Prod_count2-Prod_count1 ) ,2)  AS Difference FROM CTE1 RIGHT JOIN CTE2 ON CTE1.segment=CTE2.segment ORDER BY round((Prod_count2-Prod_count1 ) ,2) Desc ;

## Get the products that have the highest and lowest manufacturing costs.
(SELECT   DISTINCT(P.product_code),P.product ,max(M.manufacturing_cost) AS Manufacturing_cost  FROM gdb023.dim_product P  INNER  JOIN 
gdb023.fact_manufacturing_cost  M ON P.product_code=M.product_code  GROUP BY P.product_code,product 
ORDER BY max(M.manufacturing_cost) DESC LIMIT 1)
UNION ALL
(SELECT   DISTINCT(P.product_code),P.product ,min(M.manufacturing_cost)AS Manufacturing_cost   FROM gdb023.dim_product P  INNER  JOIN 
gdb023.fact_manufacturing_cost  M ON P.product_code=M.product_code  GROUP BY P.product_code,P.product
ORDER BY min(M.manufacturing_cost) ASC LIMIT 1)

##Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
##for the fiscal year 2021 and in the Indian market.The final output cONtains these fields, customer_code 
##customer average_discount_percentage

SELECT DISTINCT(C.customer_code),C.customer ,100*(Round(Avg(I.pre_invoice_discount_pct),3))AS average_discount_percentage FROM gdb023.dim_customer C  inner JOIN 
gdb023.fact_pre_invoice_deductiONs  I ON C.customer_code=I.customer_code WHERE C.market='India' AND I.fiscal_year=2021
GROUP BY C.customer_code,C.customer  ORDER BY average_discount_percentage Desc Limit 5


##Exclusive” for each mONth . This analysis helps to get an idea of low and
##high-performing mONths and take strategic decisiONs.The final report cONtains these columns:
##MONth,Year,Gross sales Amount

SELECT month(S.date) AS month,year(date)AS year,Round(sum( (S.sold_quantity)*(G.gross_price)),2)AS Gross_sales_amount 
FROM gdb023.fact_sales_monthly S 
INNER JOIN gdb023.dim_customer C ON S.customer_code=C.customer_code 
INNER JOIN  gdb023.fact_gross_price G ON S.product_code=G.product_code and S.fiscal_year=G.fiscal_year
WHERE C.customer='Atliq Exclusive' 
GROUP BY month,year ORDER BY year,month



##In which quarter of 2020, got the maximum total_sold_quantity?
##The final output cONtains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity 

WITH 
     CTE AS (SELECT month(S.date)AS month, S.sold_quantity AS Sales ,
	
CASe
     WHEN month(S.date) IN (9,10,11) Then 'First Quarter'
     WHEN month(S.date) IN (12,1,2) Then 'SecONd Quarter'
     WHEN month(S.date) IN (3,4,5) Then 'Third Quarter'
     Else  'Fourth Quarter'
 End AS Quarters
 FROM gdb023.fact_sales_mONthly S WHERE S.fiscal_year=2020)
 SELECT CTE.Quarters,sum(CTE.Sales) AS total_sold_quantity FROM CTE 
 GROUP BY CTE.Quarters
 
  
## Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
 WITH 
   CTE AS(SELECT Distinct(C.channel) as channels, sum((Round(((G.gross_price)*(S.sold_quantity)),2))) OVER(PARTITION BY (C.channel)) AS gross_sales_mln FROM gdb023.dim_customer C 
    JOIN gdb023.fact_sales_mONthly S ON S.customer_code=C.customer_code 
    JOIN  gdb023.fact_gross_price G ON S.product_code=G.product_code 
   WHERE S.fiscal_year=2021)
SELECT * ,  Round(gross_sales_mln*100/(SELECT  sum(gross_sales_mln) from CTE ),2) as Percentage  from CTE  ORDER BY Percentage DESC
   
 ## Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
 WITH CTE3 AS(
 WITH TOP_3 AS (SELECT p.product, s.product_code,p.division,SUM(sold_quantity) as Total_quantity_sold
 FROM gdb023.fact_sales_monthly AS s
 JOIN gdb023.dim_product AS p
 on s.product_code=p.product_code
 WHERE s.fiscal_year=2021 GROUP BY s.product_code,p.division,p.product
 ORDER BY Total_quantity_sold)
 SELECT *,RANK() OVER(PARTITION BY division ORDER BY Total_quantity_sold DESC) as top_rank
 FROM TOP_3)
 
 SELECT * FROM CTE3 WHERE top_rank IN (1,2,3)