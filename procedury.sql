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
