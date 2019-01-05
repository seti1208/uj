
--Tworzenie kilku logicznych urządzeń kopii zapasowych */
USE master
EXEC sp_addumpdevice 'disk', 'nw1', 'c:\...\backup\nw1.bak' 
EXEC sp_addumpdevice 'disk', 'nwlog', 'c:\...\backup\nwlog.bak'

/* Tworzenie kilku logicznych urządzeń kopii zapasowej */
USE master
EXEC sp_addumpdevice 'disk', 'nwstripe1', 'c:\...\backup\nwstripe1.bak' 
EXEC sp_addumpdevice 'disk', 'nwstripe2', 'c:\...\backup\nwstripe2.bak'

Wyświetlenie informacji o zawartości trwałego pliku (urządzenia) kopii zapasowych

restore filelistonly from nazwa_urządzenia

Wykonanie pełnej kopii zapasowej bazy danych na „urządzenie” (do trwałego pliku kopii zapasowych)

/* Tworzy kopię zapasową bazy danych Northwind na urządzeniu logicznym Nw1 */
Use Master
BACKUP DATABASE Northwind TO Nw1 
WITH FORMAT, DESCRIPTION = 'Pierwsza pełna kopia bezpieczeństwa bazy danych Northwind', NAME = 'PełnaNorthwind'

Wykonanie pełnej kopii zapasowej bazy danych do pliku tymczasowego

/* Tworzy kopię zapasową bazy danych Northwind w pliku tymczasowym Nw1.bak */
Use Master
BACKUP DATABASE Northwind TO Disk=’E:\Kopie\Nw1.bak’
WITH FORMAT, DESCRIPTION = 'Pierwsza pełna kopia bezpieczeństwa bazy danych Northwind', NAME = 'PełnaNorthwind'

Wyświetlenie informacji o zawartości pliku tymczasowego kopii zapasowych

restore filelistonly from disk = ścieżka_dostępu_do_pliku


Dodanie kolejnej pełnej kopii zapasowej bazy danych do urządzenia

/*Dodaje nową kopię do urządzenia NW1*/
BACKUP DATABASE Northwind to Nw1
with NOINIT , DESCRIPTION = 'Druga pełna kopia Northwind'

Nadpisanie urządzenia nową pełną kopią zapasową

/* Zastępuje istniejący plik kopii zapasowej nową kopią zapasową. */
BACKUP DATABASE Northwind to Nw1
WITH INIT ,
DESCRIPTION = 'Trzecia kopia zapasowa bazy danych Northwind zapisująca wszystkie poprzednie'

Tworzenie równoległej kopii zapasowej na wielu urządzeniach

/* Tworzenie kopii zapasowej na wielu urządzeniach, każde zawiera tylko część bazy. Jeśli urządzenia są na różnych fizycznych dyskach, to przyśpieszamy operację tworzenia i potem odczytu bazy */

BACKUP DATABASE Northwind TO Nwstripe1, Nwstripe2
WITH FORMAT,
DESCRIPTION = 'Równoległa kopia bezpieczeństwa bazy danych Northwind',
NAME = 'stripeNW'


Odtwarzanie bazy danych z pełnej kopii zapasowej

---Odtwarzanie bazy danych, zastępowanie istniejącej kopii i odzyskanie.
RESTORE DATABASE NWCOPY FROM NWC2
WITH REPLACE, RECOVERY

Odtwarzanie bazy danych z drugiej kopii na urządzeniu

---Odtwarzanie bazy danych z drugiej kopii na urządzeniu, zastępowanie 
---istniejącej kopii i odzyskanie.
RESTORE DATABASE NWCOPY FROM NWC2
WITH FILE=2, REPLACE, RECOVERY

Tworzenie kopii zapasowej dziennika transakcji

/* Tworzenie kopii zapasowej dziennika transakcji */

BACKUP LOG Northwind TO MwLog
DESCRIPTION = 'Kopia dziennika transakcji bazy Northwind'

Tworzenie kopii zapasowej dziennika transakcji bez obcinania dziennika

/* Tworzenie kopii zapasowej dziennika transakcji bez obcinania dziennika
   tzn. bez usuwania nieaktywnych wpisów. */

BACKUP LOG Northwind TO MwLog WITH NO_TRUNCATE


Obcięcie dziennika transakcji bez wykonania kopii zapasowej

Uwaga – ta opcja nie działa począwszy od SQL Serwera 2008. 

/* Obcięcie dziennika transakcji bez wykonania kopii zapasowej*/

BACKUP LOG Northwind TO MwLog WITH TRUNCATE_ONLY

Przykład ilustrujący odtworzenie bazy do znacznika (MARK) ustawionego w transakcji

BEGIN TRANSACTION RoyaltyUpdate 
   WITH MARK 'Update royalty values'
GO
USE pubs
GO
UPDATE roysched
   SET royalty = royalty * 1.10
   WHERE title_id LIKE 'PC%'
GO
COMMIT TRANSACTION RoyaltyUpdate
GO
--Time passes. Regular database 
--and log backups are taken.
--An error occurs.
USE master
GO

RESTORE DATABASE pubs
FROM Pubs1
WITH FILE = 3, NORECOVERY
GO
RESTORE LOG pubs
   FROM Pubs1
   WITH FILE = 4,
   STOPATMARK = 'RoyaltyUpdate'

Przykład ilustrujący odtworzenie bazy do pewnej chwili

RESTORE DATABASE MyNwind
   FROM MyNwind_1, MyNwind_2
   WITH NORECOVERY
RESTORE LOG MyNwind
   FROM MyNwindLog1
   WITH NORECOVERY
RESTORE LOG MyNwind
   FROM MyNwindLog2
   WITH RECOVERY, STOPAT = 'Apr 15, 1998 12:00 AM'
