--Tego typu funkcje są mocniejszą alternatywą dla widoków. Widok może zawierać tylko zdanie SELECT, ponadto nie może być parametryzowany. Funkcje zwracające zestaw wierszy mogą mieć rozbudowaną logikę.
--Przykład (Books Online):
CREATE FUNCTION LargeOrderShippers ( @FreightParm money )
RETURNS @OrderShipperTab TABLE
   (
    ShipperID     int,
    ShipperName   nvarchar(80),
    OrderID       int,
    ShippedDate   datetime,
    Freight       money
   )
AS
BEGIN
   INSERT INTO @OrderShipperTab
        SELECT S.ShipperID, S.CompanyName,
               O.OrderID, O.ShippedDate, O.Freight
        FROM Shippers AS S INNER JOIN Orders AS O
              ON S.ShipperID = O.ShipVia
        WHERE O.Freight > @FreightParm
   RETURN
END
--Wywołanie funkcji:
SELECT * FROM dbo.LargeOrderShippers( $500 )


--Funkcje zwracające zestawy wierszy (inline)
--Tego typu funkcje mają funkcjonalność widoków sparametryzowanych.
Rozważmy następujący widok (przykład z Books Online):

CREATE VIEW vw_CustomerNamesInWA AS
SELECT CustomerID, CompanyName
FROM Northwind.dbo.Customers
WHERE Region = 'WA'

--Taki widok wybiera dane tylko z regionu WA. Gdybyśmy chcieli użyć parametru zamiast stałej ‘WA’, 
--musimy utworzyć funkcję typu inline. 

CREATE FUNCTION fn_CustomerNamesInRegion
                 ( @RegionParameter nvarchar(30) )
RETURNS table
AS
RETURN (
        SELECT CustomerID, CompanyName
        FROM Northwind.dbo.Customers
        WHERE Region = @RegionParameter
       )
GO
-- Example of calling the function for a specific region
SELECT *
FROM fn_CustomerNamesInRegion(N'WA')
GO
--Klauzula RETURNS zawiera tylko słowo TABLE, natomiast po RETURN należy w nawiasach umieścić zdanie SELECT, 
--wykorzystujące parametr bądź parametry funkcji.


IF OBJECT_ID('DBO.UFNZ9','FN') IS NOT NULL
	DROP FUNCTION DBO.UFNZ9
GO
-- Uwaga! Dla funkcji typu inline typ obiektu to 'IF', dla
-- funkcji zwracające zestaw wierszy to 'TF'
CREATE FUNCTION dbo.ufnZ9(@Data DATE)
RETURNS NVARCHAR(20)
AS
BEGIN
RETURN (CASE DATEPART(dw,@Data)
		WHEN 1 THEN 'Niedziela'
		WHEN 2 THEN 'Poniedziałek'
		WHEN 3 THEN 'Wtorek'
		WHEN 4 THEN 'Środa'
		WHEN 5 THEN 'Czwartek'
		WHEN 6 THEN 'Piątek'
		WHEN 7 THEN 'Sobota'
END)
END
GO

SELECT dbo.ufnZ9(GETDATE())

--Proszę przy wykorzystaniu powyższej funkcji wypisać zdaniem SQL dla każdego dnia tygodnia sumę kwot uzyskanych 
--za sprzedaż w dany dzień. W sumie ma być 7 wierszy posortowanych malejąco według kwoty 
--(na górze powinny być dane dla ‘najlepszego’ dnia tygodnia).

--Proszę napisać funkcję, która wypisze dla każdego klienta sumę kwot jakie klient wydał na zamówienia towaru 
--o podanym jako argument identyfikatorze. Jeśli towar nie będzie podany, wówczas funkcja ma zwrócić sumę kwot 
--dla wszystkich towarów na wszystkich zamówieniach (dla każdego klienta).

CREATE FUNCTION dbo.ufnZ10 (@IdProduktu INT)
RETURNS @Tab TABLE (Idklienta NCHAR(5), Kwota MONEY)
AS
BEGIN
IF @IdProduktu IS NULL
	INSERT INTO @Tab
	SELECT CustomerID, SUM(Quantity*UnitPrice*(1- Discount)) Kwota
	FROM [Order Details] OD JOIN Orders O ON OD.OrderID = O.OrderID
	GROUP BY CustomerID
	ORDER BY Kwota DESC
ELSE	
INSERT INTO @Tab
	SELECT CustomerID, SUM(Quantity*UnitPrice*(1- Discount)) Kwota
	FROM [Order Details] OD JOIN Orders O ON OD.OrderID = O.OrderID
	WHERE ProductID=@IdProduktu
	GROUP BY CustomerID
	ORDER BY Kwota DESC
RETURN	
END

SELECT * FROM dbo.ufnZ10(1)

SELECT CompanyName, CustomerID, Kwota FROM dbo.ufnz10(1) F JOIN Customers C ON F.Idklienta = C.CustomerID

SELECT * FROM dbo.ufnZ10(NULL)

SELECT CompanyName, CustomerID, Kwota FROM dbo.ufnz10(NULL) F JOIN Customers C ON F.Idklienta = C.CustomerID
