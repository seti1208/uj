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
INSERT INTO T1 VALUES (6,600),(7,700)
--Nie kończ transakcji. Zmień bazę danych na MASTER.
USE MASTER
--Zatrzymaj serwer. Wykonaj symulację awarii: usuń plik CW.MDF.
--Odtwórz bazę danych po awarii.

--backup dziennika uszkodzonej bazy z NO_TRUNCATE
BACKUP LOG CW TO DISK='C:\tmp\CW_log3.bak' WITH NO_TRUNCATE
--przywrócenie bazy
--1 sposob
GO
RESTORE DATABASE CW FROM DISK='C:\tmp\CW_pelna.bak' 
WITH STANDBY='C:\tmp\nowanazwa.bak'
--2 sposob
RESTORE DATABASE CW FROM DISK='C:\tmp\CW_pelna.bak' 
WITH NORECOVERY
