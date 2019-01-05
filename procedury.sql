--utworzenie
GO
CREATE PROC uspZ1 (@Cena MONEY)
AS
SELECT * FROM dbo.Products
WHERE UnitPrice >= @Cena
ORDER BY UnitPrice DESC, ProductName
GO

--Można również napisać 
CREATE PROCEDURE uspZ1 ( @Cena MONEY )
AS ...
--lub:
CREATE PROCEDURE uspZ1 @Cena MONEY  --nawiasy nie są konieczne
AS ...

--Wywołanie procedury (3 sposoby):
EXEC uspZ1 20
EXEC uspZ1 @Cena=20
EXEC dbo.uspZ1 @Cena=20

--Usunięcie procedury:
DROP PROC uspZ1

--Wartości domyślne parametrów, zmiana procedury uspZ1.
ALTER PROC uspZ1 (@Cena1 MONEY=0, @Cena2 MONEY=922337203685477.5807 )
AS
SELECT * FROM dbo.Products
WHERE UnitPrice >= @Cena1 AND UnitPrice <= @Cena2
ORDER BY UnitPrice DESC, ProductName

--Przypomnienie: zamiast
WHERE UnitPrice >= @Cena1 AND UnitPrice <= @Cena2
--można napisać:
WHERE UnitPrice BETWEEN @Cena1 AND @Cena2

--Aby zapobiec wypisywaniu komunikatu o liczbie wierszy objętych działaniem instrukcji SQL, należy w sesji wykonać:
SET NOCOUNT ON

/*Proszę napisać procedurę składowaną, która wypisze wszystkie produkty z kategorii, 
której nazwa podana jest jako parametr, przy czym chodzi tylko o produkty o najwyższej cenie w tej kategorii. 
Procedura powinna mieć również parametr wyjściowy (OUTPUT), którego wartość ma być ustawiona w procedurze na liczbę produktów
w podanej kategorii.*/

IF OBJECT_ID('DBO.uspZ2','P') IS NOT NULL
	DROP PROC DBO.uspZ2
GO
CREATE PROC uspZ2 (@NazwaKategorii NVARCHAR(15), @Ile INT OUTPUT)
--zamiast OUTPUT można skrótowo napisać @Ile INT OUT 

AS
DECLARE @IdKategorii INT
DECLARE @MaksCena MONEY

--Najpierw należy odnaleźć identyfikator kategorii o podanej nazwie
SET @IdKategorii = (SELECT CategoryID FROM Categories 
					WHERE CategoryName=@NazwaKategorii)
-- Można też tak: 
-- SELECT @IdKategorii = CategoryID 
-- FROM Categories WHERE CategoryName=@NazwaKategorii

-- Teraz można wyznaczyć maksymalną ceną jednostkową towaru w tej kategorii
SET @MaksCena = (SELECT MAX(UnitPrice) FROM dbo.Products 
				 WHERE CategoryID=@IdKategorii)
-- Można też tak: 
-- SELECT @MaksCena = MAX(UnitPrice) FROM dbo.Products
-- WHERE CategoryID=@IdKategorii)

SELECT * FROM Products 
WHERE CategoryID=@IdKategorii AND UnitPrice=@MaksCena
					
SET @Ile = (SELECT COUNT(*) FROM Products 
			WHERE CategoryID=@IdKategorii)
GO

--Wywołanie procedury z parametrem wyjściowym
DECLARE @Ile_produktow INT
EXECUTE uspZ2 'Beverages', @Ile_produktow OUT --lub OUTPUT

SELECT @Ile_produktow
GO

--Proszę napisać procedurę składowaną, która będzie służyć do dopisywania jednego wiersza do tabeli [Order Details].
--Cena jednostkowa ma być przepisywana z tabeli Products.
IF OBJECT_ID('DBO.uspZ3','P') IS NOT NULL
	DROP PROC DBO.uspZ3
GO
CREATE PROC uspZ3 
	@IdZamowienia INT, 
	@IdProduktu INT,
	@Ilosc SMALLINT=1,
	@Znizka REAL=0
AS
DECLARE @IleWMagazynie INT
DECLARE @Cena MONEY

IF NOT EXISTS (SELECT OrderID FROM Northwind.dbo.Orders WHERE OrderID=@IdZamowienia)
BEGIN
	RAISERROR('Nie ma zamówienia o numerze %d', 16,1, @IdZamowienia)
	RETURN(1)
END	

IF NOT EXISTS (SELECT ProductID FROM Northwind.dbo.Products WHERE ProductID=@IdProduktu)
BEGIN
	RAISERROR('Nie ma produktu o numerze %d', 16,1, @IdProduktu)
	RETURN(2)
END	

IF EXISTS (SELECT OrderID FROM Northwind.dbo.[Order Details] 
		   WHERE OrderID=@IdZamowienia AND ProductID=@IdProduktu)
BEGIN
	RAISERROR('Produkt o podanym numerze %d jest juz wpisany do zamowienia %d. Nie można go wpisać drugi raz.'
	, 16,1, @IdProduktu, @IdZamowienia)
	RETURN(3)
END	

SET @IleWMagazynie = (SELECT UnitsInStock FROM Northwind.dbo.Products 
					  WHERE ProductID=@IdProduktu)
IF @IleWMagazynie <@Ilosc 
BEGIN
	RAISERROR('Nie ma żądanej ilości produktu %d', 16,1, @IdProduktu)
	RETURN(4)
END	

UPDATE Northwind.dbo.Products 
SET UnitsInStock = UnitsInStock - @Ilosc, 
	UnitsOnOrder = UnitsOnOrder + @Ilosc
WHERE ProductID = @IdProduktu


SET @Cena = (SELECT UnitPrice FROM Northwind.dbo.Products WHERE ProductID=@IdProduktu) 

INSERT INTO Northwind.dbo.[Order Details] 
VALUES (@IdZamowienia, @IdProduktu, @Cena, @Ilosc, @Znizka)

RETURN(0)

GO

--Działanie procedury można sprawdzić np. na poniższych danych. 
DECLARE @Kod INT
EXECUTE @Kod=dbo.uspZ3 45077,145,2,0
PRINT 'Kod wyjścia = '+ cast(@Kod as varchar(1))

DECLARE @Kod INT
EXECUTE @Kod=dbo.uspZ3 11077,145,2,0
PRINT 'Kod wyjścia = '+ cast(@Kod as varchar(1))

DECLARE @Kod INT
EXECUTE @Kod=dbo.uspZ3 11077,1,2,0
PRINT 'Kod wyjścia = '+ cast(@Kod as varchar(1))

DECLARE @Kod INT
EXECUTE @Kod=dbo.uspZ3 11077,5,2,0
PRINT 'Kod wyjścia = '+ cast(@Kod as varchar(1))

DECLARE @Kod INT
EXECUTE @Kod=dbo.uspZ3 11077,9,1,0
PRINT 'Kod wyjścia = '+ cast(@Kod as varchar(1))
