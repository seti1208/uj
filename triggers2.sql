/* Napisać wyzwalacz, który pozwoli na dopisanie do
tabeli SF (Szczegóły faktur) tylko poprawnych numerów towaru lub usługi.
Numery towarów są w tabeli Towary, numery
usług są w tabeli Usługi, wiięc nie da się utworzyć więzów klucza obcego w tabeli SF
(bo klucz obcy może się odwoływać tylko do jednej tabeli. */
CREATE TABLE Uslugi(
NrUslugi INT PRIMARY KEY CHECK(NrUslugi >100),
Nazwa NVARCHAR(100) NOT NULL,
CenaGodz MONEY NULL)

CREATE TABLE Towary(
NrTowaru INT PRIMARY KEY CHECK(NrTowaru BETWEEN 1 AND 100),
Nazwa NVARCHAR(100) NOT NULL,
CenaSzt MONEY NULL)

CREATE TABLE SF(NrFaktury INT NOT NULL,
NrUslugiLubTowaru INT NOT NULL,
Ilosc INT NOT NULL,
PRIMARY KEY(NrFaktury, NrUslugiLubTowaru))

INSERT INTO Towary VALUES
(1,'ABC',10),(2,'XYZ',4),(5,'CCC',12)
INSERT INTO Uslugi VALUES
(101,'U101',10),(105,'U105',20)
GO
CREATE TRIGGER TrKluczObcy ON SF
AFTER INSERT
AS
IF EXISTS (SELECT NrUslugiLubTowaru FROM inserted
           WHERE NrUslugiLubTowaru NOT IN (SELECT NrUslugi 
										   FROM Uslugi)
           AND NrUslugiLubTowaru NOT IN (SELECT NrTowaru 
										   FROM Towary)
		   )
	ROLLBACK
GO

SELECT * FROM Uslugi
SELECT * FROM Towary
SELECT * FROM SF

--To się nie uda:
INSERT INTO SF VALUES
(1000,101,1),(1000,105,1),(1000,2,1),(1000,233,1)

--Ale to się wykona poprawnie:
INSERT INTO SF VALUES
(1000,101,1),(1000,105,1),(1000,2,1)

DELETE FROM SF

--Inna wersja tego wyzwalacza. Tym razem chcemy, żeby wyzwalacz
--pozwalał na wpisanie poprawnych numerów towarów 
--i usług a odrzucał tylko te niepoprawne
GO
ALTER TRIGGER TrKluczObcy ON SF
INSTEAD OF INSERT
AS
INSERT INTO SF
SELECT * FROM inserted
WHERE NrUslugiLubTowaru IN (SELECT NrUslugi FROM Uslugi)
  OR  NrUslugiLubTowaru IN (SELECT NrTowaru FROM Towary)
GO
