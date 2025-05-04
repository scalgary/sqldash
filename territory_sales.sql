USE AdventureWorks2019;
GO
SELECT 
  ST.TerritoryID,
  CONCAT(ST.Name, ', ', ST.CountryRegionCode) AS Territories,
  (SUM(SOH.TotalDue) / SUM(SOD.OrderQty)) AS AverageOrderValue,
  SUM(SOH.TotalDue) AS Totalsales
FROM Sales.SalesTerritory ST
INNER JOIN Sales.SalesOrderHeader SOH ON ST.TerritoryID = SOH.TerritoryID
INNER JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY ST.TerritoryID, CONCAT(ST.Name, ', ', ST.CountryRegionCode)
ORDER BY Totalsales DESC;
GO