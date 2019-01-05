--Wyzwalacze (triggers) działajace na instrukcjach
--DELETE, INSERT, UPDATE

DROP TABLE T1
CREATE TABLE T1(k1 INT PRIMARY KEY, k2 INT)

INSERT INTO T1 VALUES(1,100),(2,200)
INSERT T1 VALUES(3,300)

--Poniższy wyzwalacz uniemożliwi wprowadzanie nowych rekordów do tabeli T1
SELECT * FROM T1
GO
CREATE TRIGGER T1Tr1 ON T1
AFTER INSERT
AS
	ROLLBACK
	RAISERROR('Nie można dopisywać do T1',16,1)
GO

INSERT INTO T1 VALUES(4,400),(5,500)
SELECT * FROM T1

--Zmieńmy ten wyzwalacz tak, by był uruchamiany dla zdania UPDATE
--i wypiszmy zawartość tabel T1, deleted i inserted.
--UWAGA!!!!! Normalnie wyzwalacz nie powinien nic wypisywać, 
--ponieważ działa "w tle". My wypisujemy tylko dla celów poznawczych.
GO
ALTER TRIGGER T1Tr1 ON T1
AFTER UPDATE
AS
	SELECT * FROM deleted
	SELECT * FROM inserted
	SELECT * FROM T1
	ROLLBACK
GO

--Zobaczmy jak to będzie wyglądać, jeśli zmienimy wyzwalacz z AFTER UPADTE
--na INSTEAD OF UPDATE (i usuniemy ROLLBACK):

ALTER TRIGGER T1Tr1 ON T1
INSTEAD OF UPDATE
AS
	SELECT * FROM deleted
	SELECT * FROM inserted
	SELECT * FROM T1
GO

UPDATE T1
SET k2=k1*100
WHERE k1 IN (1,2)

SELECT * FROM T1

--Wypiszmy zawartość deleted i inserted w wyzwalaczu zbudowanym
--na tabeli Products:

GO
CREATE TRIGGER ProductsTr1 ON Products
AFTER UPDATE
AS
IF UPDATE(UnitPrice) -- sprawdzamy, czy zaktualizowana została 
                     -- kolumna UnitPrice
BEGIN
	SELECT * FROM deleted
	SELECT * FROM inserted
	ROLLBACK
END

SELECT * FROM Products

UPDATE Products
SET UnitPrice = UnitPrice - 1
WHERE ProductID IN (1,3)

--Wyłączenie działania wyzwalacza ProductsTr1 
--(ale sam wyzwalacz nie jest usuwany z bazy danych)

ALTER TABLE Products 
DISABLE TRIGGER ProductsTr1

--Wyłączenie działania wszystkich wyzwalaczy na tabeli Products
ALTER TABLE Products 
DISABLE TRIGGER ALL

--Włączenie działania wszystkich wyzwalaczy na tabeli Products
ALTER TABLE Products 
ENABLE TRIGGER ALL

--Wróćmy do tabeli ze szczegółami zamówień:
SELECT * FROM [Order Details]
WHERE OrderID = 10248

--Wprowadźmy nową pozycję - produkt numer 3
--na zamówienie o identyfikatorze 10248
--(użyjemy procedury napisanej na poprzednich zajęciach)
--(plik tsql_przyklady):
exec uspZ3 10248,3,12,0

--Usuńmy ten produkt z zamówienia 
DELETE FROM [Order Details]
WHERE OrderID = 10248 AND ProductID = 3

--Dodajmy go jeszcze raz, tym razem przy pomocy 
--zdania INSERT. Teraz możemy wprowadzić niepoprawną cenę
--do kolumny UnitPrice. Produkt numer 3 kosztuje 10.00 
--(można to sprawdzić w tabeli Products), ale
--my wpiszemy np. 5:
INSERT INTO [Order Details] VALUES(10248,3,5,12,0)

DELETE FROM [Order Details]
WHERE OrderID = 10248 AND ProductID = 3

SELECT * FROM [Order Details]
WHERE OrderID = 10248

--Napiszmy wyzwalacz, który wprowadzi poprawną cenę.
--Na razie będzie to uproszczona wersja, która zadziała
--bez błędu tylko, jesli jednym zdaniem INSERT dodamy
--tylko jeden rekord do tabeli [Order Details]:
GO
CREATE TRIGGER ODTr1 ON [Order Details]
INSTEAD OF INSERT
AS
DECLARE @Cena MONEY
DECLARE @IdProduktu INT
--Poniższa instrukcja będzie przyczyną błędu wykonania
--jeśli tabela inserted zawiera więcej niż jeden rekord
--(będzie to próba wprowadzenie więcej niż jednej wartości 
--do zmiennej skalarnej typu INT):
SET @IdProduktu = (SELECT ProductID FROM inserted)
SET @Cena = (SELECT UnitPrice FROM Products 
             WHERE ProductID = @IdProduktu)
INSERT INTO [Order Details]
SELECT I.OrderID, I.ProductID, @Cena, 
I.Quantity, I.Discount
FROM inserted AS I
GO

--Sprawdźmy jak to działa, jesli jedną instrukcją INSERT
--dodamy tylko jeden rekord do [Order Details]:
INSERT INTO [Order Details] VALUES(10248,3,5,12,0)
SELECT * FROM [Order Details]
WHERE OrderID = 10248
--Widzimy, że cena została prowadzona poprawnie, tj.
--wyzwalacz zamienił 5 na 10.

DELETE FROM [Order Details]
WHERE OrderID = 10248 AND ProductID = 3

SELECT * FROM [Order Details]
WHERE OrderID = 10248

--Ale jeśli spróbujemy wpisać dwa rekordy jednym zdaniem
--INSERT, wówczas zgłoszony zostanie błąd wykonania 
--"sub-query returned more than one value".
INSERT INTO [Order Details] VALUES
(10248,3,5,12,0),(10248,4,1,3,0)
GO

--Zmieńmy wyzwalacz tak, by działał poprawnie:
ALTER TRIGGER ODTr1 ON [Order Details]
INSTEAD OF INSERT
AS
SET NOCOUNT ON
INSERT INTO [Order Details]
SELECT I.OrderID, I.ProductID, (SELECT UnitPrice FROM Products AS P
                                WHERE P.ProductID = I.ProductID), 
I.Quantity, I.Discount
FROM inserted AS I
GO

--Teraz uda się wpisanie dwóch rekordów jednym zdaniem INSERT:
INSERT INTO [Order Details] VALUES
(10248,3,5,12,0),(10248,4,1,3,0)

SELECT * FROM [Order Details]
WHERE OrderID = 10248

DELETE FROM [Order Details]
WHERE OrderID = 10248 AND ProductID IN (3,4)

SELECT * FROM [Order Details]
WHERE OrderID = 10248

--Do tej pory pisaliśmy wersje tego wyzwalacza
--typu INSTEAD OF INSERT

--Zmieńmy to na AFTER INSERT:
ALTER TRIGGER ODTr1 ON [Order Details]
AFTER INSERT
AS
SET NOCOUNT ON
UPDATE OD 
SET UnitPrice = (SELECT UnitPrice FROM Products AS P
                 WHERE P.ProductID = OD.ProductID)
FROM [Order Details] AS OD JOIN inserted AS I 
ON I.OrderID = OD.OrderID AND I.ProductID= OD.ProductID
GO

--Inna wersja:
ALTER TRIGGER ODTr1 ON [Order Details]
AFTER INSERT
AS
SET NOCOUNT ON
UPDATE OD 
SET UnitPrice = P.UnitPrice
FROM [Order Details] AS OD JOIN inserted AS I 
ON I.OrderID = OD.OrderID AND I.ProductID= OD.ProductID
JOIN Products AS P ON OD.ProductID = P.ProductID
GO

--Zadanie 5 z pliku tsql_przyklady:
IF OBJECT_ID('Tr1','TR') IS NOT NULL
	DROP TRIGGER Tr1
go
CREATE TRIGGER Tr1 ON [Order Details]
AFTER INSERT
AS
DECLARE @TabProdNaZamowieniach TABLE (IdProduktu INT, Ilosc INT)

INSERT INTO @TabProdNaZamowieniach
SELECT ProductID, SUM(Quantity) FROM Inserted GROUP BY ProductID

IF EXISTS (SELECT ProductID FROM Products P JOIN @TabProdNaZamowieniach T ON P.ProductID=T.IdProduktu
		   WHERE UnitsInStock < Ilosc)
BEGIN		   
	ROLLBACK
	RAISERROR('Zbyt duża ilość pewnego produktu na zamówieniu',16,1)
END	
ELSE
BEGIN
UPDATE OD SET UnitPrice = 
					(SELECT Unitprice FROM Products P
					 WHERE P.ProductID=OD.ProductID)
FROM [Order Details] OD JOIN INSERTED I 
ON OD.OrderID=I.OrderID AND OD.ProductID=I.ProductID

UPDATE P SET UnitsInStock -= Ilosc, UnitsOnOrder += Ilosc
FROM Products P JOIN @TabProdNaZamowieniach T ON P.ProductID=T.IdProduktu

END
GO

SELECT * FROM [Order Details]
WHERE OrderID IN (10248,10249)

SELECT * FROM Products WHERE ProductID IN (1,3)

INSERT INTO [Order Details] VALUES
(10248,1,0.50,3,0),(10248,3,1,1,0),(10249,1,2,30,0)

SELECT * FROM Products


--Utwórzmy wyzwalacz, który będzie rejestrował zmiany cen
--produktów w tabeli Products. Informacja o zmianach
--ma być wpisywana do tabeli Products_Log:
CREATE TABLE Products_Log(Nr INT IDENTITY(1,1) PRIMARY KEY,
Data_i_Godzina DATETIME,
Kto NVARCHAR(100))

SELECT * FROM Products_Log

SELECT GETDATE()
SELECT SUSER_SNAME()
GO
DROP TRIGGER ProductsLogTr1
GO

--Pierwsza wersja wyzwalacza - rejestrujemy tylko
--datę z godziną zmiany oraz login osoby, która zmianę wykonała:
CREATE TRIGGER ProductsLogTr1 ON Products
AFTER UPDATE
AS
INSERT INTO Products_Log
VALUES(GETDATE(), SUSER_SNAME())
GO

SELECT * FROM Products

DROP TRIGGER ProductsTr1

UPDATE Products SET UnitPrice += 1
WHERE ProductID IN (1,3)

SELECT * FROM Products

SELECT * FROM Products_Log

GO
ALTER TRIGGER ProductsLogTr1 ON Products
AFTER UPDATE
AS
INSERT INTO Products_Log
SELECT GETDATE(), SUSER_SNAME()
GO

SELECT GETDATE(), SUSER_SNAME()

UPDATE Products SET UnitPrice -= 1
WHERE ProductID IN (1,3)

SELECT * FROM Products
SELECT * FROM Products_Log

GO
ALTER TRIGGER ProductsLogTr1 ON Products
AFTER UPDATE
AS
INSERT INTO Products_Log
SELECT GETDATE(), SUSER_SNAME()
FROM inserted
GO

UPDATE Products SET UnitPrice += 1
WHERE ProductID IN (1,3)

SELECT * FROM Products
SELECT * FROM Products_Log

--Dodajmy kolumny NrProduktu i NowaCena do tabeli Products_Log:
ALTER TABLE Products_Log 
ADD NrProduktu INT, NowaCena MONEY

SELECT * FROM Products_Log
GO

--Zmodyfikujmy wyzwalacz tak, by rejestrował
--identyfikator produktu i nową cenę dla wszystkich
--produktów, które zmieniły cenę:
ALTER TRIGGER ProductsLogTr1 ON Products
AFTER UPDATE
AS
INSERT INTO Products_Log
SELECT GETDATE(), SUSER_SNAME(),
I.ProductID, I.UnitPrice
FROM inserted AS I
GO

UPDATE Products SET UnitPrice -= 1
WHERE ProductID IN (1,3)

SELECT * FROM Products
SELECT * FROM Products_Log

--Dodajmy jeszcze kolumnę StaraCena
ALTER TABLE Products_Log
ADD StaraCena MONEY

SELECT * FROM Products_Log

GO
ALTER TRIGGER ProductsLogTr1 ON Products
AFTER UPDATE
AS
INSERT INTO Products_Log
SELECT GETDATE(), SUSER_SNAME(),
I.ProductID, I.UnitPrice, D.UnitPrice
FROM inserted AS I JOIN deleted AS D
ON I.ProductID = D.ProductID
GO

UPDATE Products SET UnitPrice += 1
WHERE ProductID IN (1,3)

SELECT * FROM Products
SELECT * FROM Products_Log

--Ostateczna wersja wyzwalacza rejestrującego zmiany cen:
GO
ALTER TRIGGER ProductsLogTr1 ON Products
AFTER UPDATE
AS
SET NOCOUNT ON
IF UPDATE(UnitPrice)
	INSERT INTO Products_Log
	SELECT GETDATE(), SUSER_SNAME(),
	I.ProductID, I.UnitPrice, D.UnitPrice
	FROM inserted AS I JOIN deleted AS D
	ON I.ProductID = D.ProductID
GO

UPDATE Products SET UnitPrice=UnitPrice
WHERE ProductID =1

SELECT * FROM Products
SELECT * FROM Products_Log


--Zadanie:
--Proszę napisać wyzwalacz, który nie pozwoli na wykonanie zdania UPDATE
--(tj. wykona ROLLBACK), jeśli wartość w kolumnie k2 zmieni się
--w przynajmniej jednym zmienianym rekordzie na mniejszą:

DROP TABLE T1

CREATE TABLE T1
(k1 INT PRIMARY KEY,
 k2 INT)

INSERT INTO T1 VALUES(1,100),(2,200),(3,300)
SELECT * FROM T1

GO
--Zakładamy, że tylko jeden rekord jest aktualizowany
CREATE TRIGGER T1Tr1 ON T1
AFTER UPDATE
AS
IF UPDATE (k2)
BEGIN
	DECLARE @k1 INT, @OldK2 INT, @NewK2 INT
	SET @k1 = (SELECT k1 FROM inserted)-- w zasadzie @k1 jest niepotrzebne
	SET @OldK2 = (SELECT k2 from 
	              deleted WHERE k1 = @k1)
    SET @NewK2 = (SELECT k2 from 
	              inserted WHERE k1 = @k1)
	IF @NewK2 < @OldK2
	BEGIN
		ROLLBACK
		RAISERROR('Nie można zmniejszać wartości w k2',16,1)
    END
END
SELECT * FROM T1
UPDATE T1 SET k2 = 30 WHERE k1=1
SELECT * FROM T1
UPDATE T1 SET k2 = 30 WHERE k1 IN (1,3)

--Możemy wymusić, że aktualizacja musi dotyczyć tylko 
--jednego rekordu (chociaż na ogół nie powinniśmy tego robić):
GO
ALTER TRIGGER T1Tr1 ON T1
AFTER UPDATE
AS
IF UPDATE (k2)
BEGIN
	IF (SELECT COUNT(*) FROM inserted) > 1
	BEGIN
		ROLLBACK
		RAISERROR('Mozna aktualizować tylko jeden rekord',16,1)
	END
	ELSE
	BEGIN
		DECLARE @k1 INT, @OldK2 INT, @NewK2 INT
		SET @k1 = (SELECT k1 FROM inserted)
		SET @OldK2 = (SELECT k2 from 
					deleted WHERE k1 = @k1)
		SET @NewK2 = (SELECT k2 from 
					inserted WHERE k1 = @k1)
		IF @NewK2 < @OldK2
		BEGIN
			ROLLBACK
			RAISERROR('Nie można zmniejszać wartości w k2',16,1)
        END
    END
END

SELECT * FROM T1
UPDATE T1 SET k2 = 130 WHERE k1=1
SELECT * FROM T1
UPDATE T1 SET k2 = 30 WHERE k1 IN (1,3)

--Ostateczna wersja wyzwalacza:
GO
ALTER TRIGGER T1Tr1 ON T1
AFTER UPDATE
AS
IF UPDATE (k2)
BEGIN
  IF EXISTS (SELECT I.k1 FROM inserted AS I JOIN deleted AS D ON I.k1=D.k1
             WHERE I.k2 < d.k2)
  BEGIN
	ROLLBACK
	RAISERROR('Nie mozna zmniejszac wartości w k2',16,1)
  END
END

SELECT * FROM T1
UPDATE T1 SET k2 = K2+1 WHERE k1 IN (1,3)

SELECT * FROM T1

UPDATE T1 SET k2 = K2-1 WHERE k1 IN (1,3)

UPDATE T1 SET k2 = 150 WHERE k1 IN (1,2)

SELECT * FROM T1


UPDATE T1 SET k2 = 30 WHERE k1 IN (1,3)

--Teraz zmieńmy sposób działania wyzwalacza - 
--Tym razem chcemy, żeby zmiany k2 na wartość większą były akceptowane
--a nie wykonają się tylko te na wartość mniejszą. Oczywiście
--chodzi o zmiany wykonane jednym zdaniem UPDATE.
GO
ALTER TRIGGER T1Tr1 ON T1
INSTEAD OF UPDATE
AS
IF UPDATE (k2)
BEGIN
	UPDATE T1
	SET k2 = I.k2
	FROM T1 JOIN inserted AS I ON T1.k1 = I.k1
	JOIN deleted AS D ON I.k1 = D.k1 
	WHERE I.k2>=D.k2
END

--Prostsza wersja - w zasadzie nie musimy sięgać do deleted 
--po starą wartość k2. Wystarczy odwołać się do T1.k2.
--Wyzwalacz jest typu INSTEAD OF UPDATE, więc w trakcie
--jego działania wartość t1.k2 jest "stara".
GO
ALTER TRIGGER T1Tr1 ON T1
INSTEAD OF UPDATE
AS
IF UPDATE (k2)
BEGIN
	UPDATE T1
	SET k2 = I.k2
	FROM T1 JOIN inserted AS I ON T1.k1 = I.k1
	WHERE I.k2>=T1.k2
END

SELECT * FROM T1
UPDATE T1 SET k2 = 150 WHERE k1 IN (1,2)

SELECT * FROM T1

