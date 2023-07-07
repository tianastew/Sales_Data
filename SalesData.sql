-- Inspecting Data
SELECT * 
FROM dbo.sales_data

--Checking Unique Values
SELECT DISTINCT STATUS FROM dbo.sales_data --Good to plot
SELECT DISTINCT YEAR_ID FROM dbo.sales_data
SELECT DISTINCT PRODUCTLINE FROM dbo.sales_data --Good to plot
SELECT DISTINCT COUNTRY FROM dbo.sales_data --Good to plot
SELECT DISTINCT DEALSIZE FROM dbo.sales_data --Good to plot
SELECT DISTINCT TERRITORY FROM dbo.sales_data --Good to plot

SELECT DISTINCT MONTH_ID FROM dbo.sales_data
WHERE year_id = 2003


---ANALYSIS
--Grouping sales by productline
SELECT PRODUCTLINE, SUM(sales) AS REVENUE
FROM dbo.sales_data
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

SELECT YEAR_ID, SUM(sales) AS REVENUE
FROM dbo.sales_data
GROUP BY YEAR_ID
ORDER BY 2 DESC

SELECT DEALSIZE, SUM(sales) AS REVENUE
FROM dbo.sales_data
GROUP BY DEALSIZE
ORDER BY 2 DESC

--What was the best month for sales in a specific year? How much was earned that month?
SELECT MONTH_ID, SUM(sales) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM dbo.sales_data
WHERE YEAR_ID = 2004 --I will change the year to see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC


--Nov appears to be the most profitable month, what product is sold in Nov?
SELECT MONTH_ID, PRODUCTLINE, SUM(sales) AS REVENUE, COUNT(ORDERNUMBER) FREQUENCY
FROM dbo.sales_data
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 --I will change the year to see the rest
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC


--What customer spends the most? (best answered with RFM)


DROP TABLE IF EXISTS #RFM
;WITH RFM AS
(
SELECT
CUSTOMERNAME,
SUM(SALES) AS MONETARYVALUE,
AVG(SALES) AS AVGMONETARYVALUE,
COUNT(ORDERNUMBER) AS FREQUENCY,
MAX(ORDERDATE) AS LAST_ORDER_DATE,
(SELECT MAX(ORDERDATE) FROM dbo.sales_data) AS MAX_ORDER_DATE,
DATEDIFF(DD,MAX(ORDERDATE),(SELECT MAX(ORDERDATE) FROM dbo.sales_data)) AS RECENCY
FROM dbo.sales_data
GROUP BY CUSTOMERNAME
),
RFM_CALC AS
(

SELECT R.*,
NTILE(4) OVER (ORDER BY RECENCY DESC) RFM_RECENCY,
NTILE(4) OVER (ORDER BY FREQUENCY) RFM_FREQUENCY,
NTILE(4) OVER (ORDER BY MONETARYVALUE) RFM_MONETARY
FROM RFM R
)
SELECT
C.*, RFM_RECENCY+ RFM_FREQUENCY+ RFM_MONETARY AS RFM_CELL,
CAST(RFM_RECENCY AS varchar)+ CAST(RFM_FREQUENCY AS varchar)+ CAST(RFM_MONETARY AS varchar) AS RFM_CELL_STRING
INTO #RFM
FROM RFM_CALC C

SELECT CUSTOMERNAME, RFM_RECENCY, RFM_FREQUENCY, RFM_MONETARY,
CASE
WHEN RFM_CELL_STRING IN (111, 112, 113, 114, 121, 122, 123, 124, 131, 132, 141, 142, 211, 212, 213, 214, 221, 231, 241) THEN 'Lost Customer' --Lost Customers
WHEN RFM_CELL_STRING IN (133, 134, 143, 144, 234, 243, 244, 313, 314, 324, 334, 343, 344) THEN 'Slipping Away, Cannot Lose' --Big spenders who haven't purchased in recently
WHEN RFM_CELL_STRING IN (311, 312, 331, 411) THEN 'New Customer' 
WHEN RFM_CELL_STRING IN (222, 223, 224, 232, 233, 242, 322) THEN 'Potential Churner' -- Customers that havent purchased very recently and/or havent spent alot
WHEN RFM_CELL_STRING IN (321, 323, 332, 333, 341, 342, 412, 413, 414, 421, 422, 423, 424, 431, 432, 441, 442) THEN 'Active' --Customers who bought recently and often but smaller purchases
WHEN RFM_CELL_STRING IN (433, 434, 443, 444) THEN 'Loyal' --Customers who buy a lot and often
END RFM_SEGMENT

FROM #RFM



--What products are most often sold together?
--As well as what should be put on sale at the same time?

SELECT DISTINCT ORDERNUMBER, STUFF(

(SELECT ',' + PRODUCTCODE
FROM dbo.sales_data AS P
WHERE ORDERNUMBER IN
(
SELECT ORDERNUMBER
FROM(
SELECT ORDERNUMBER, COUNT(*) RN
FROM dbo.sales_data
WHERE STATUS = 'Shipped'
GROUP BY ORDERNUMBER
) M
WHERE RN = 3
)
AND P.ORDERNUMBER = S.ORDERNUMBER
FOR XML PATH ('')) 

,1, 1, '') AS PRODUCTCODES


FROM dbo.sales_data AS S
ORDER BY 2 DESC