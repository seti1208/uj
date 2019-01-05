--tworzenie bazy i tabeli
USE MASTER
GO
CREATE DATABASE CW
GO
USE CW
CREATE TABLE T1(p1 INT PRIMARY KEY, p2 INT)
INSERT INTO T1 VALUES (1,100)
--backup
BACKUP DATABASE CW TO DISK='C:\tmp\CW_pelna.bak'

INSERT INTO T1 VALUES (2,200)
BACKUP DATABASE CW TO DISK='C:\tmp\CW_roznicowa1.bak' WITH DIFFERENTIAL

INSERT INTO T1 VALUES (3,300)
BACKUP DATABASE CW TO DISK='C:\tmp\CW_roznicowa2.bak' WITH DIFFERENTIAL

--kopia dziennika
INSERT INTO T1 VALUES (4,400)
BACKUP LOG CW TO DISK='C:\tmp\CW_log1.bak'
INSERT INTO T1 VALUES (5,500)
BACKUP LOG CW TO DISK='C:\tmp\CW_log2.bak'

--przerywanie transakcji
INSERT INTO T1 VALUES (6,600),(7,700)
BEGIN TRAN
INSERT INTO T1 VALUES (8,800),(9,900)
--Nie kończ transakcji. Zmień bazę danych na MASTER.
USE MASTER
--Zatrzymaj serwer. Wykonaj symulację awarii: usuń plik CW.MDF.
--Odtwórz bazę danych po awarii.

--backup dziennika uszkodzonej bazy z NO_TRUNCATE
BACKUP LOG CW TO DISK='C:\tmp\CW_log3.bak' WITH NO_TRUNCATE
-----------------------------------
--przywrócenie bazy
--1 sposob
GO
RESTORE DATABASE CW FROM DISK='C:\tmp\CW_pelna.bak' 
WITH STANDBY='C:\tmp\nowanazwa.bak'
--do bazy można nawet zaglądnąć:
USE CW 
GO
SELECT * FROM T1

--2 sposob
RESTORE DATABASE CW FROM DISK='C:\tmp\CW_pelna.bak' 
WITH NORECOVERY

--Odtwórz bazę z ostatniej kopii różnicowej
RESTORE DATABASE CW FROM DISK='C:\tmp\CW_roznicowa2.bak' 
WITH STANDBY='C:\tmp\nowanazwa.bak'
USE CW 
GO
SELECT * FROM T1

--Odtwórz bazę  z pliku CW_log1.bak 
USE MASTER
RESTORE DATABASE CW FROM DISK='C:\tmp\CW_log1.bak' 
WITH STANDBY='C:\tmp\nowanazwa.bak'
USE CW 
GO
SELECT * FROM T1

--Odtwórz bazę  z pliku CW_log2.bak
USE MASTER
RESTORE DATABASE CW FROM DISK='C:\tmp\CW_log2.bak' 
WITH STANDBY='C:\tmp\nowanazwa.bak'
USE CW 
GO
SELECT * FROM T1

--Odtwórz bazę  danych z pliku CW_log3.bak z opcją WITH RECOVERY
USE MASTER
RESTORE DATABASE CW FROM DISK='C:\tmp\CW_log3.bak' 
WITH RECOVERY
USE CW 
GO
SELECT * FROM T1

--Zadanie 2
--Odtwarzanie systemu bazy danych do pewnego momentu. Odtwarzanie częściowe (wybranych grup plików).

--Dodaj grupę plików o nazwie Grupa2 i umieść w niej plik CW_gr2.ndf o nazwie logicznej CW_2. 
--W grupie plików Grupa2 utwórz tabelę T2 (x1 int, x2 int). 
--Dodaj grupę plików Grupa3 i umieść w niej plik CW_gr3.ndf o nazwie logicznej cw_3, następnie w tej grupie utwórz tabelę T3(y1 int, y2 int). 

ALTER DATABASE CW
ADD FILEGROUP GRUPA2

ALTER DATABASE CW
ADD FILE (NAME = 'CW_2', FILENAME = 'C:\....\CW_GR2.NDF')
TO FILEGROUP GRUPA2

ALTER DATABASE CW
ADD FILEGROUP GRUPA3

ALTER DATABASE CW
ADD FILE (NAME = 'CW_3', FILENAME = 'C:\....\CW_GR3.NDF')
TO FILEGROUP GRUPA3

USE CW 
GO
CREATE TABLE T2(x1 INT PRIMARY KEY, x2 INT) ON GRUPA2
CREATE TABLE T3(y1 INT PRIMARY KEY, y2 INT) ON GRUPA3

--Wpisz do T2 i T3 jednakowe wiersze (1,100).
INSERT INTO T2 VALUES(1,100)
INSERT INTO T3 VALUES(1,100)

--Zrób pełną kopię zapasową bazy CW. Dodaj do T2 i T3 wiersze (2,200) i (3,300).
BACKUP DATABASE CW TO DISK='C:\....\CW_KOPIA.BAK'
INSERT INTO T2 VALUES(2,200)
INSERT INTO T3 VALUES(2,200)

--Zapisz datę z godziną: SELECT GetDate() (możesz np. użyć tabeli pomocniczej).
CREATE TABLE #POMOCNICZA(NR INT IDENTITY(1,1) PRIMARY KEY, CZAS DATETIME)
INSERT INTO #POMOCNICZA(CZAS) VALUES(GETDATE())
SELECT * FROM #POMOCNICZA

--Skasuj tabelę T2. Wstaw do T3 wiersze (4,400) i (5,500).
DROP TABLE T2
INSERT INTO T3 VALUES(3,300)
INSERT INTO T3 VALUES(4,400)

--Odtwórz tabelę T2.

/* Strategia odtwarzania tabeli T2 nie może być oparta na odtworzeniu bazy danych z pełnej kopii i potem 
z kopii dziennika z zatrzymaniem na godzinie sprzed skasowania tabeli T2, 
ponieważ zostałyby utracone wszystkie inne transakcje z bazy danych wykonane po tej godzinie 
(w naszym przypadku jest to wstawienie wierszy (3,300) i (4,400) to T3).

Właściwa strategia polega na odtworzeniu bazy danych do innej bazy i potem skopiowaniu tabeli T2. 
W przypadku dużych baz danych podzielonych na grupy plików można nawet nie odtwarzać całej bazy 
(mogłoby to zając nawet kilka godzin), tylko wybrane grupy plikow
Uwaga – grupa o nazwie PRIMARY (z plikiem *.MDF) musi być zawsze odtworzona. 
Taka strategia będzie użyta w tym ćwiczeniu.

Należy zrobić kopię zapasową bieżącego dziennika transakcji z opcją COPY_ONLY (żeby bieżący dziennik nie został obcięty). */
BACKUP LOG CW TO DISK='C:\TEMP\CW_LOG.BAK' WITH COPY_ONLY

--Należy odtworzyć bazę danych CW z pełnej kopii do bazy z inną nazwą, np. CWA (zastosowane opcje to MOVE oraz NORECOVERY). 
RESTORE DATABASE CWA FILEGROUP = 'GRUPA2'
FROM DISK='C:\TEMP\CW_KOPIA.BAK' 
WITH PARTIAL, NORECOVERY, 
MOVE 'CW' TO 'C:\....\CWA.MDF', -- grupa PRIMARY musi być zawsze odtworzona
MOVE 'CW_2' TO 'C:\....\CWA_2.NDF',
MOVE 'CW_LOG' TO 'C:\....\CWA_LOG.LDF' --dziennik transakcji

--Następnie należy odtworzyć bazę (a właściwie grupę plików PRIMARY i GRUPA2) z dziennika transakcji z opcją STOPAT = (tu podać zapisaną wcześniej godzinę).
DECLARE @CZAS DATETIME
SET @CZAS=(SELECT CZAS FROM #POMOCNICZA WHERE NR=1)
RESTORE LOG CWA FROM DISK='C:\....\CW_LOG.BAK' WITH STOPAT = @CZAS, RECOVERY
USE CW
SELECT * INTO t2 FROM CWA.dbo.T2

--Zadanie 3
--Odtwarzanie systemu bazy danych do wybranej transakcji nazwanej. 

/*Bazę danych można odtworzyć do pewnej transakcji (włącznie lub wyłącznie), wykorzystując nazwane transakcje 
i opcja odtwarzania STOPATMARK lub STOPBEFOREMARK. Ilustrują to poniższe przykłady z Books Online:*/
USE AdventureWorks
GO
BEGIN TRANSACTION ListPriceUpdate
   WITH MARK 'UPDATE Product list prices';-- opis podany w apostrofach jest opcjonalny
GO

UPDATE Production.Product
   SET ListPrice = ListPrice * 1.10
   WHERE ProductNumber LIKE 'BK-%';
GO

COMMIT TRANSACTION ListPriceUpdate;
GO

-- Time passes. Regular database 
-- and log backups are taken.
-- An error occurs in the database.
USE master
GO

-- Poniżej zastosowano odtwarzanie z tzw. trwałego pliku kopii zapasowych. 
-- Taki plik jest określany mianem device lub urządzenie i należy go 
-- najpierw utworzyć procedurą sp_addumpdevice. Jest to plik, który
-- może być traktowany jak urządzenie, do którego można wstawić wiele kopii
-- zapasowych bazy danych i dziennika transakcji. Kopie te są ponumerowane.
-- Polecenie RESTORE HEADERONLY wypisuje zawartość 
-- takiego pliku–urządzenia.

RESTORE DATABASE AdventureWorks
FROM AdventureWorksBackups – podano tu nazwę urządzenia (pliku trwałego)
WITH FILE = 3, NORECOVERY; -- 3 oznacza trzecią kopię w pliku kopii
GO

RESTORE LOG AdventureWorks
   FROM AdventureWorksBackups 
   WITH FILE = 4,
   RECOVERY, 
   STOPATMARK = 'ListPriceUpdate';
 
--Proszę przećwiczyć powyższy schemat odtwarzania na bazie danych CW.

Zadanie 4
Trwałe pliki kopii zapasowych. 

Proszę utworzyć trwały plik kopii zapasowych (np. o nazwie dev1). Proszę umieścić w pliku pełną kopię bazy danych CW. Proszę wykonać zmianę w bazie danych, a następnie umieścić w pliku drugą kopię zapasową pełną. Proszę obejrzeć zawartość urządzenia zarówno w oknie Management Studio jak i poleceniem T-SQL. Proszę odtworzyć bazę danych z pierwszej kopii.

Zadanie 5
Kopie równoległe. 

Proszę utworzyć dwa trwałe pliki kopii zapasowych (np. o nazwie d1 i d2). Proszę wykonać pełną kopię zapasową na obydwu urządzeniach. 

Zadanie 6
Jeszcze jeden przykład z grupą plików. 

Proszę w bazie danych CW utworzyć grupę plików GR4 z dwoma plikami. Proszę umieścić tam tabelę. Następnie proszę usunąć jeden z plików grupy.
Wskazówka – najpierw należy przepisać zawartość pliku do drugiego. Można to zrobić przez DBCC SHRINKFILE z opcją EMPTY_FILE. 
Następnie proszę przesunąć tabelę do innej grupy plików.
