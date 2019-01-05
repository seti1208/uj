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
AS
--lub:
CREATE PROCEDURE uspZ1 @Cena MONEY  --nawiasy nie są konieczne
AS
--Wywołanie procedury (3 sposoby):
EXEC uspZ1 20
EXEC uspZ1 @Cena=20
EXEC dbo.uspZ1 @Cena=20
