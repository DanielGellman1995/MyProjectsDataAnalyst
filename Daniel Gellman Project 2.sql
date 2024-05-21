--Project Name: Project 2
-- by: Daniel Gellman
-- ID : 205948797
-- Q1
SELECT p.ProductID,Name,Color ,ListPrice, Size  FROM Production.Product p 
LEFT JOIN Sales.SalesOrderDetail s ON p.ProductID = s.ProductID
WHERE s.SalesOrderDetailID IS NULL
ORDER BY p.ProductID 
--Q2

SELECT c.CustomerID , 
ISNULL(p.FirstName,'Unknown') AS FirstNmae , 
ISNULL(p.LastName,'Unknown') AS LastName FROM sales.Customer c 
LEFT JOIN Person.Person p ON p.BusinessEntityID = c.CustomerID
LEFT JOIN Sales.SalesOrderHeader sh ON c.CustomerID = sh.CustomerID
WHERE sh.CustomerID IS NULL


--Q3
SELECT DISTINCT TOP 10 * FROM (
SELECT  c.CustomerID ,p.FirstName,p.LastName, COUNT(s.SalesOrderID) OVER (PARTITION BY s.CustomerID) AS CountOfOrders FROM sales.Customer c
JOIN Person.Person p ON p.BusinessEntityID = c.CustomerID
JOIN Sales.SalesOrderHeader s ON s.CustomerID = c.CustomerID
) AS myorders
ORDER BY myorders.countoforders DESC
-- מציין שהשמות שונים אבל המזהה לקוח דומה אצלי כמו בטבלת הדוגמא

-- Q4 
SELECT FirstName,LastName , JobTitle , HireDate , 
COUNT(e.BusinessEntityID) OVER(PARTITION BY e.JobTitle) AS CountOfTitle FROM person.person p
JOIN HumanResources.Employee e ON e.BusinessEntityID=p.BusinessEntityID

--Q5

WITH ORDERSTABLE AS (
SELECT s.SalesOrderID, c.CustomerID , s.OrderDate, c.PersonID ,
DENSE_RANK() OVER (PARTITION BY c.PersonID ORDER BY s.OrderDate DESC) AS LASTORDER 
FROM sales.Customer c
LEFT JOIN sales.SalesOrderHeader s ON c.CustomerID = s.CustomerID )

SELECT p.FirstName,p.LastName ,SalesOrderID,CustomerID 
,OrderDate, LAG(OrderDate) OVER(ORDER BY LASTORDER) AS PreviousOrder FROM ORDERSTABLE
LEFT JOIN Person.Person p ON p.BusinessEntityID = ORDERSTABLE.PersonID
WHERE LASTORDER = 1 AND SalesOrderID IS NOT NULL 


--Q6

WITH maxorder AS  	
	(
	SELECT YEAR(sh.OrderDate) AS Year, sh.CustomerID,sh.SalesOrderID,  SUM(so.UnitPrice*(1-so.UnitPriceDiscount)*so.OrderQty) AS Total,
	row_number() OVER(PARTITION BY YEAR(sh.OrderDate) ORDER BY SUM(so.UnitPrice*(1-so.UnitPriceDiscount)*so.OrderQty) DESC) AS ranking
	FROM Sales.SalesOrderHeader sh
	JOIN Sales.SalesOrderDetail so ON sh.SalesOrderID = so.SalesOrderID
	GROUP BY  YEAR(sh.OrderDate), sh.SalesOrderID , sh.CustomerID 
	) 

	SELECT Year,SalesOrderID, p.LastName,p.FirstName,Total  FROM maxorder
	JOIN Sales.Customer c ON c.CustomerID = maxorder.CustomerID
	JOIN Person.Person p ON p.BusinessEntityID = c.PersonID
	WHERE maxorder.ranking = 1


--Q7
SELECT Month , ISNULL([2011],0) AS '2011' , [2012] , [2013],ISNULL([2014],0) AS '2014' FROM
(
SELECT DISTINCT MONTH(OrderDate) AS Month, YEAR(sh.OrderDate) AS syear , COUNT(s.SalesOrderID) AS ccount FROM sales.SalesOrderDetail s
JOIN Sales.SalesOrderHeader sh ON sh.SalesOrderID = s.SalesOrderID
GROUP BY MONTH(OrderDate) , YEAR(sh.OrderDate)) AS s
PIVOT(SUM(ccount)for syear IN ([2011],[2012],[2013],[2014])) AS pvt

--Q8
WITH f AS (
SELECT YEAR(SOH.orderdate) AS Year 
, MONTH(SOH.OrderDate) AS Month 
, SUM(SOD.UnitPrice)
AS sumu FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY YEAR(SOH.orderdate),  MONTH(SOH.OrderDate)),

 CumulativeData AS(
SELECT Year ,Month ,
SUM(sumu) OVER (PARTITION BY Month ORDER BY Year) AS Sum_Price,
SUM(sumu) OVER (ORDER BY Year , Month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS CumSum 
FROM f
) 
SELECT Year,
Month,
CAST(Sum_Price AS VARCHAR(20)) AS Sum_Price,
  CAST(CumSum AS VARCHAR(20)) AS CumSum
FROM CumulativeData
UNION ALL
SELECT
  Year,
  13 AS Month, 
  'Grand Total' AS Sum_Price,
  CAST(MAX(cumsum) AS VARCHAR(20)) 
FROM CumulativeData
WHERE Month = 12
GROUP BY Year
ORDER BY Year, Month

--Q9

SELECT DepartmentName, EmployeesID ,EmployeesFullName , HireDate , Seniority ,LEAD(EmployeesFullName) OVER (PARTITION BY DepartmentName ORDER BY Seniority) AS PreviuseEmpName  ,  
LEAD(HireDate) OVER(PARTITION BY DepartmentName ORDER BY seniority)AS PreviusEmpDate , 
DATEDIFF(DAY ,LEAD(HireDate) OVER(PARTITION BY DepartmentName ORDER BY seniority), HireDate) AS DiffDays
 FROM
(
SELECT hd.Name AS DepartmentName, HE.BusinessEntityID AS employeesID , FirstName + ' ' + LastName AS EmployeesFullName ,
HireDate ,  DATEDIFF(MONTH , hiredate, GETDATE()) AS Seniority  FROM HumanResources.Employee AS HE
JOIN HumanResources.EmployeeDepartmentHistory AS EDH ON HE.BusinessEntityID = EDH.BusinessEntityID
JOIN HumanResources.Department AS HD ON HD.DepartmentID = EDH.DepartmentID
JOIN Person.Person p ON p.BusinessEntityID = he.BusinessEntityID
) AS MT

--Q10


WITH EmployeeTeams
AS
(
    SELECT e.HireDate,
           ed.DepartmentID,
           p.LastName + ' ' + p.FirstName AS "Employee'sFullName",
           CAST(e.BusinessEntityID AS VARCHAR) AS BusinessEntityID
    FROM HumanResources.Employee AS e JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
    JOIN HumanResources.EmployeeDepartmentHistory AS ed ON e.BusinessEntityID = ed.BusinessEntityID
    JOIN HumanResources.Department AS d ON ed.DepartmentID = d.DepartmentID
    WHERE ed.EndDate IS NULL
)
SELECT HireDate,
       DepartmentID,
       STRING_AGG(BusinessEntityID + ' ' + [Employee'sFullName], ', ') AS TeamEmployees
FROM EmployeeTeams AS e1
GROUP BY HireDate, DepartmentID
ORDER BY HireDate DESC


