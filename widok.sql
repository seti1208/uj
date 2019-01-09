CREATE VIEW vw_CustomerNamesInWA AS
SELECT CustomerID, CompanyName
FROM Northwind.dbo.Customers
WHERE Region = 'WA'

--Taki widok wybiera dane tylko z regionu WA. Dalej przejdź do funkcji
