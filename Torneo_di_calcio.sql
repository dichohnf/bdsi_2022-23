DROP DATABASE IF EXISTS `bdsi_prog2023`;
CREATE DATABASE IF NOT EXISTS `bdsi_prog2023`;

USE bdsi_prog2023;

SET GLOBAL local_infile = 'ON';

CREATE TABLE IF NOT EXISTS Torneo(
    codice		VARCHAR(5)				-- T-xxx
				PRIMARY KEY,
	nome		VARCHAR(30) NOT NULL,
    edizione	TINYINT UNSIGNED
				DEFAULT 1 NOT NULL,
    genere		ENUM('M','F','N') NOT NULL,
    tipologia	TINYINT UNSIGNED NOT NULL,
    
    UNIQUE (nome, genere, tipologia, edizione)
);

CREATE TABLE IF NOT EXISTS Fase(
    codice		VARCHAR(6) 				-- F-xxxx
				PRIMARY KEY,
    torneo		VARCHAR(5) NOT NULL,
    nome		VARCHAR(40) NOT NULL,
    modalita	ENUM('Girone','Eliminazione') NOT NULL,
    scontri		TINYINT UNSIGNED 
				DEFAULT 1 NOT NULL,
                
	UNIQUE (torneo, nome),
	FOREIGN KEY (torneo)
		REFERENCES Torneo(codice)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Insieme_squadre(
    codice		VARCHAR(7) 				-- I-xxxxx
				PRIMARY KEY,
    fase		VARCHAR(6) NOT NULL,
    nome		CHAR(1) DEFAULT NULL, 	/* Lettera dell'alfabeto
										 * o NULL per le Fasi con un solo Insieme di squadre */
	UNIQUE (fase, nome),
    FOREIGN KEY (fase)
		REFERENCES Fase(codice)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Campo(
	codice		VARCHAR(5)				-- C-xxx 
				PRIMARY KEY,
    nome		VARCHAR(50) NOT NULL,
    telefono 	VARCHAR(15) DEFAULT NULL,
    comune		VARCHAR(40) NOT NULL,
    via			VARCHAR(40) NOT NULL,
    civico		SMALLINT UNSIGNED NOT NULL,
    UNIQUE(comune, via, civico),
    UNIQUE (nome, comune)
);

CREATE TABLE IF NOT EXISTS Squadra(
    codice			VARCHAR(8) PRIMARY KEY,	-- S-xxxxxx
	nome			VARCHAR(40) NOT NULL,
    tipologia		TINYINT UNSIGNED NOT NULL,
    genere			ENUM('M','F','N') NOT NULL,
    colori			VARCHAR(30) DEFAULT NULL,
	campo			VARCHAR(5) NOT NULL,

    FOREIGN KEY (campo)
		REFERENCES Campo(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Raggruppamento(
	insieme_squadre 	VARCHAR(7),
    squadra 			VARCHAR(8),
    
	PRIMARY KEY (insieme_squadre, squadra),
    FOREIGN KEY (insieme_squadre)
		REFERENCES Insieme_squadre(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (squadra)
		REFERENCES Squadra(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Giornata(
    codice			VARCHAR(7) PRIMARY KEY,		-- G-xxxxx
	insieme_squadre	VARCHAR(7) NOT NULL,
	numero			TINYINT UNSIGNED NOT NULL,
    
    UNIQUE (insieme_squadre, numero),
    FOREIGN KEY (insieme_squadre)
		REFERENCES Insieme_squadre(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Giocatore(
	tessera			SMALLINT UNSIGNED PRIMARY KEY,
	nome			VARCHAR(100) NOT NULL,		-- La dimensione elevata permette l'inserimento di secondi nomi
    cognome			VARCHAR(100) NOT NULL,		-- La dimensione elevata permette l'inserimento di vari cognomi
    genere			ENUM('M','F','N') NOT NULL,
    data			DATE NOT NULL,
    
    UNIQUE (nome, cognome, data)
);

CREATE TABLE IF NOT EXISTS Rosa(
	squadra		VARCHAR(8),
    giocatore	SMALLINT UNSIGNED ,
    numero_maglia TINYINT UNSIGNED,
    
    PRIMARY KEY(squadra, giocatore),
	UNIQUE (squadra, numero_maglia),
    FOREIGN KEY (squadra)
		REFERENCES Squadra(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (giocatore)
		REFERENCES Giocatore(tessera)
        ON DELETE CASCADE
        ON UPDATE CASCADE

);

CREATE TABLE IF NOT EXISTS Arbitro(
	tessera			SMALLINT UNSIGNED PRIMARY KEY,
	nome			VARCHAR(100) NOT NULL,		-- La dimensione elevata permette l'inserimento di secondi nomi
    cognome			VARCHAR(100) NOT NULL,		-- La dimensione elevata permette l'inserimento di vari cognomi
    genere			ENUM('M','F','N') NOT NULL,
    data			DATE NOT NULL,
    
	UNIQUE (nome, cognome, data)
);

CREATE TABLE IF NOT EXISTS Partita(
    codice				VARCHAR(9) PRIMARY KEY,		-- P-xxxxxxx
	squadra_casa		VARCHAR(8) NOT NULL,
    squadra_ospite		VARCHAR(8) NOT NULL,
    giornata			VARCHAR(7) NOT NULL,
    giorno 				DATE NOT NULL,
    ora					TIME NOT NULL,
    gol_casa			TINYINT UNSIGNED,
    gol_ospite			TINYINT UNSIGNED,
    campo				VARCHAR(5) NOT NULL,
    arbitro				SMALLINT UNSIGNED  NOT NULL,
    
    FOREIGN KEY(squadra_casa)
		REFERENCES Squadra(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY(squadra_ospite)
		REFERENCES Squadra(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY(giornata)
		REFERENCES Giornata(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY(campo)
		REFERENCES Campo(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY(arbitro)
		REFERENCES Arbitro(tessera)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	UNIQUE (squadra_casa, squadra_ospite, giornata)
);

CREATE TABLE IF NOT EXISTS Statistiche(
	giocatore			SMALLINT UNSIGNED NOT NULL,
    partita				VARCHAR(9) NOT NULL,
    gol					TINYINT UNSIGNED DEFAULT 0 NOT NULL,
    assist				TINYINT UNSIGNED DEFAULT 0 NOT NULL,
	ammonizioni			TINYINT UNSIGNED DEFAULT 0 NOT NULL,
	espulsione_giornate	TINYINT UNSIGNED DEFAULT 0 NOT NULL,
    
    PRIMARY KEY (giocatore, partita),
    FOREIGN KEY(giocatore)
		REFERENCES Giocatore(tessera)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY(partita)
		REFERENCES Partita(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


/*
 * SEZIONE DEDICATA ALLE PROCEDURE, ALLE FUNZIONI E ALLE VISTE AUSILIARIE
 */
 
/*
 * La successiva vista rappresenta l'inisieme di tutti i tesseramenti.
 * Occorre per operare la creazione di una nuova tessera.
 */

CREATE VIEW tesseramenti
(tessera, nome, cognome, data, genere) AS 
(SELECT * FROM Giocatore UNION SELECT * FROM Arbitro);
	
/*
 * La successiva vista rappresenta l'insieme dei tornei che sono terminati.
 * Per associare ad un torneo l'attributo di "terminato" viene preso come
 * discriminante la terminazione di tutte le partite del torneo. 
 */
CREATE VIEW tornei_terminati
(codice, nome, edizione, genere, tipologia) AS
(SELECT * FROM Torneo WHERE codice IN
	(SELECT torneo FROM Fase WHERE codice IN 
		(SELECT fase FROM Insieme_squadre WHERE codice IN 
			(SELECT insieme_squadre FROM Giornata WHERE
			codice IN (SELECT giornata FROM Partita) AND													-- Giornata con almeno una partita definita
            codice NOT IN (SELECT giornata FROM Partita WHERE gol_casa IS NULL OR gol_ospite IS NULL)))));	-- Giornata con nessuna partita (NOT IN) non terminata (IS NULL) 
            
/*
 * La successiva vista rappresenta l'insieme dei codici delle squadre partecipanti
 * associati ai tornei a cui partecipano e in quali fasi dei suddetti tornei.
 * Questa vista occorre per la verivica del vincolo di partecipazione singola
 * di una squadra ad una fase
 */
CREATE VIEW squadra_iscrizioni
(torneo, fase, insieme, squadra) AS
SELECT torneo, fase, insieme, squadra FROM 
(SELECT F.torneo AS torneo, F.codice AS fase, I.codice AS insieme FROM Fase F, Insieme_squadre I WHERE F.codice = I.fase) AS TFI 
NATURAL JOIN 
(SELECT insieme_squadre AS insieme, squadra FROM Raggruppamento) AS R;
    
/*
 * SEZIONE DEDICATA AI TRIGGER
 * La sezione successiva definisce i trigger per il controllo 
 * dei vincoli non esprimibili tramite i costrutti del linguaggio.
 * Per ogni tabelle è stato preferito mantenere un trigger unico
 * al fine di agevolare il lettore. Questo rendere lo script meno
 * frastagliato ma costringe ad una struttura interna non sempre immediata 
 * (esempio, prima vengono inserite tutte le dichiarazioni utili per 
 * tutti i controlli da eswguire nel trigger poi il resto).
 * I trigger relativi agli inserimenti (i primi della lista) 
 * condividono una sezione per il controllo del formato del codice.
 * Non è stato possibile implementare una procedura unica per tutti
 * i trigger per limitazioni del linguaggio: non è possibile
 * utilizzare in questi i meccanismi dinamici di SQL (es. prepared functions)
 * per il riconoscimento della tabella da cui eseguire la ricerca
 * dell'indice minimo del codice.
 * I trigger per gli inserimenti quindi controllano il formato del 
 * codice e, qualora non sia corretto, lo assegnano, individuano l'indice 
 * minimo tra quelli disponibili. (Non è detto che le istanze inserite 
 * cronologicamente dopo abbiano codice maggiore). In caso di assegnazione
 * viene restituito uno warning affinchè sia evidente l'avvenimento.
 */
 
DELIMITER $$

CREATE TRIGGER TR_INS_Torneo BEFORE INSERT ON Torneo
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127); 
	IF NEW.codice NOT LIKE 'T-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Torneo HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Torneo)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Torneo HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Torneo)) AS idx_libero_next;
        SET NEW.codice = CONCAT('T-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
    END IF;
END$$

CREATE TRIGGER TR_INS_Fase BEFORE INSERT ON Fase
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
	IF NEW.codice NOT LIKE 'F-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Fase HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Fase)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Fase HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Fase)) AS idx_libero_next;
        SET NEW.codice = CONCAT('F-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER TR_INS_Insieme_squadre BEFORE INSERT ON Insieme_squadre
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
	IF NEW.codice NOT LIKE 'I-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Insieme_squadre HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Insieme_squadre)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Insieme_squadre HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Insieme_squadre)) AS idx_libero_next;
        SET NEW.codice = CONCAT('I-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER TR_INS_Campo BEFORE INSERT ON Campo
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
	IF NEW.codice NOT LIKE 'C-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Campo HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Campo)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Campo HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Campo)) AS idx_libero_next;
        SET NEW.codice = CONCAT('C-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER TR_INS_Squadra BEFORE INSERT ON Squadra
FOR EACH ROW  
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
	IF NEW.codice NOT LIKE 'S-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Squadra HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Squadra)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Squadra HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Squadra)) AS idx_libero_next;
        SET NEW.codice = CONCAT('S-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER TR_INS_Ragguppamento BEFORE INSERT ON Raggruppamento
FOR EACH ROW
BEGIN
	DECLARE genere_squadra ENUM('M','F','N');
    DECLARE genere_torneo ENUM('M','F','N');
    
    -- Controllo genere concordante tra Squadra e Torneo
	SELECT Squadra.genere INTO genere_squadra FROM Squadra WHERE Squadra.codice = NEW.squadra;
    SELECT T.genere INTO genere_torneo FROM Torneo T WHERE T.codice = 
		(SELECT F.torneo FROM Fase F WHERE F.codice = 
			(SELECT I.fase FROM Insieme_squadre I WHERE I.codice = NEW.Insieme_squadre));
    IF genere_squadra <> genere_torneo
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='1000';
	END IF;
    
    -- Controllo che la squadra non stia gia partecipando alla fase
    IF (NEW.squadra IN 
		(SELECT isc.squadra FROM squadra_iscrizioni AS isc WHERE isc.fase IN 
			(SELECT I.fase FROM Insieme_squadre I WHERE I.codice = NEW.insieme_squadre)))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Squadra già partecipante alla fase.', MYSQL_ERRNO='1004';
    END IF;
END $$


CREATE TRIGGER TR_INS_Giornata BEFORE INSERT ON Giornata
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(127);
    DECLARE idx_prev_libero INT;
	DECLARE idx_next_libero INT;
    DECLARE n_giornate_cur 	INT UNSIGNED;
    DECLARE n_giornate_exp 	INT UNSIGNED;

    -- Controllo formato codice
	IF NEW.codice NOT LIKE 'G-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT (CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1) AS idx FROM Giornata HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Giornata)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT (CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1) AS idx FROM Giornata HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Giornata)) AS idx_libero_next;
        SET NEW.codice = CONCAT('G-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
        SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg;
	END IF;
        
    -- Controllo vincoli del numero di giornate a seconda della modalita della fase
    SET n_giornate_cur = ((SELECT COUNT(codice) FROM Giornata WHERE insieme_squadre = NEW.insieme_squadre) +1);		-- somma 1 per comprendere anche la giornata che sta venendo inserita
    IF (SELECT F.modalita FROM Fase F WHERE F.codice = 
		(SELECT I.fase FROM Insieme_squadre I WHERE I.codice = NEW.insieme_squadre)) 
	= 'Girone'
    THEN SET n_giornate_exp = (
		((SELECT COUNT(squadra) FROM Raggruppamento WHERE insieme_squadre = NEW.insieme_squadre) -1) 				-- sottratto 1 dato il vincolo #giornate = #squadre -1
        * (SELECT F.scontri FROM Fase F WHERE F.codice =
			(SELECT I.fase FROM Insieme_squadre I WHERE I.codice = NEW.insieme_squadre)));
	ELSE SET n_giornate_exp = (																						-- Caso: Fase.modalita = 'Eliminazione'
		SELECT FLOOR(LOG2((SELECT COUNT(squadra) FROM Raggruppamento WHERE insieme_squadre = NEW.insieme_squadre)))
        * (SELECT F.scontri FROM Fase F WHERE F.codice =
			(SELECT I.fase FROM Insieme_squadre I WHERE I.codice = NEW.insieme_squadre)));
	END IF;
	IF (n_giornate_cur < n_giornate_exp)																			-- se il numero di giornate presenti (current) è inferiore al numero di giornate attese (expected) viene segnalato tramite warning
	THEN
		SET warnmsg = CONCAT("Giornate insufficienti. Occorrono ulteriori ", (n_giornate_exp - n_giornate_cur), " giornate per il completamento della fase");
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg;
    END IF;
END$$

/*
 * Inesrimenti di tesserati (Giocatore e Arbitro).
 * Le tessere sono assegnate seguendo l'ordine cronologico. Le prime tessere
 * possiedono numeri bassi. Le tessere inferiori non assegnate dovranno 
 * essere assegnate manualmente, per cui si suggerisce di non specificare
 * tessere e lasciare il trigger genearle, a meno che non si desideri mantenere
 * delle tessere riservate.
 */

CREATE TRIGGER TR_INS_Giocatore BEFORE INSERT ON Giocatore
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(127);
	IF NEW.tessera IS NULL 
	THEN 
		SET NEW.tessera = COALESCE((SELECT MAX(tessera) FROM tesseramenti) + 1, 0);
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con tessera: ", NEW.tessera);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER TR_INS_Rosa BEFORE INSERT ON Rosa
FOR EACH ROW
BEGIN
	DECLARE genere_squadra ENUM('M','F','N');
    DECLARE genere_giocatore ENUM('M','F','N');
    
	-- Controllo numero_maglia appartenente al dominio 
    IF NEW.numero_maglia > 99		-- Data la tipologia UNSIGNED del dato non occorre il controllo: (... < 0)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Numero maglia non accettabile. I numeri di maglia devono essere interni compresi tra 0 e 99 inclusi.', MYSQL_ERRNO='1002';
	END IF;
    
	-- Controllo genere compatibile tra Giocatore e Squadra
	SELECT Squadra.genere INTO genere_squadra FROM Squadra WHERE Squadra.codice = NEW.squadra;
    SELECT Giocatore.genere INTO genere_giocatore FROM Giocatore WHERE Giocatore.tessera = NEW.Giocatore;
    IF genere_squadra <> 'N' AND genere_squadra <> genere_giocatore		-- Squadre miste accettano giocatori di ogni genere
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='1000';
	END IF;
END $$

CREATE TRIGGER TR_INS_Arbitro BEFORE INSERT ON Arbitro
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(127);
	IF NEW.tessera IS NULL 
	THEN 
		SET NEW.tessera = COALESCE((SELECT MAX(tessera) FROM tesseramenti) + 1, 0);
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con tessera: ", NEW.tessera);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER TR_INS_Partita BEFORE INSERT ON Partita
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
    
	-- Controllo vincolo: squadre giocanti diverse
    IF NEW.squadra_casa = NEW.squadra_ospite
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Squadre uguali. Le partite devono essere formate da due squadre distinte.", MYSQL_ERRNO=1003;
    END IF;
    
    -- Controllo formato codice
	IF NEW.codice NOT LIKE 'P-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Partita HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Partita)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Partita HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Partita)) AS idx_libero_next;
        SET NEW.codice = CONCAT('P-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
	
    
END$$

CREATE TRIGGER TR_INS_Statistiche BEFORE INSERT ON Statistiche
FOR EACH ROW
BEGIN 
	DECLARE errmsg 					VARCHAR(127);
    DECLARE squadra_casa			VARCHAR(8);
    DECLARE somma_gol 				TINYINT UNSIGNED;
    DECLARE gol_squadra_giocatore 	TINYINT UNSIGNED;
    DECLARE warnmsg					VARCHAR(127);
    

    -- Controllo ammonizioni appartenenti a {0,1,2}
    IF NEW.ammonizioni NOT IN (0,1,2)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Numero ammonizioni fuori dal dominio {0, 1, 2}.", MYSQL_ERRNO=1001;
    END IF;
    
    -- Controllo che somma dei gol corrisponda a punteggio partita
	SELECT SUM(gol) INTO somma_gol FROM Statistiche WHERE partita = NEW.partita AND giocatore IN 
		(SELECT DISTINCT giocatore FROM Rosa WHERE squadra IN (SELECT squadra FROM Rosa WHERE giocatore = NEW.giocatore));
	SELECT squadra_casa INTO squadra_casa FROM Partita WHERE codice = NEW.partita;
	SELECT IF(squadra_casa IN (SELECT squadra FROM Rosa WHERE giocatore = NEW.giocatore), gol_casa, gol_ospite) 	-- la condizione che la squadra di casa sia una di quelle del giocatore è sufficiente dato il vincolo di singola partecipazoine del giocatore ad un insieme di squadra 
		INTO gol_squadra_giocatore FROM Partita WHERE codice = NEW.partita;
    IF somma_gol <> gol_squadra_giocatore
    THEN
		SET warnmsg = CONCAT("Punteggio inconsistente. Il punteggio della partita non corrisponde alla somma dei gol: (somma gol) - (gol squadra) = ", (somma_gol - gol_squadra_giocatore));
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg, MYSQL_ERRNO='1005';
	END IF;
END $$

DELIMITER ;


/*
 * SEZIONE DEDICATA AGLI INSERIMENTI
 */

# Inserimento manuale da script (tabella Torneo)

INSERT INTO Torneo (nome, tipologia, genere, edizione)
VALUES	('Firenze Inverno',	'7','N',1),
		('Firenze Estate',	'5','N',1);
            
INSERT INTO Fase (torneo, nome, modalita, scontri)
VALUES ('T-0', 'Eliminazione unico', 'Eliminazione', 1),
	   ('T-0', 'Eliminazione bis', 'Eliminazione', 1),
	   ('T-1', 'Eliminazione unico', 'Eliminazione', 1);

INSERT INTO Campo (nome, telefono, comune, via, civico)
VALUES ('Campetto', '055055055', 'Firenze', 'via senza fine', 8);

INSERT INTO Squadra (nome, tipologia, genere, campo)
VALUES ('Ovo',		'5', 'N', 'C-0'),
	   ('Sodo',		'5', 'N', 'C-0'),
       ('Piedi',	'5', 'N', 'C-0'),
       ('Nudi',		'5', 'N', 'C-0'),
       ('Pippe',	'5', 'N', 'C-0'),
       ('Scarsi', 	'5', 'N', 'C-0');

INSERT INTO Giocatore (tessera, nome, cognome, data, genere)
VALUES  (NULL, 'Pippo', 'deVez', '2021-10-15', 'M'),
		(NULL, 'Luca', 'Micaio', '2022-02-27', 'N');
        
INSERT INTO Arbitro (tessera, nome, cognome, data, genere)
VALUES  (NULL, 'Pippo', 'deVez', '2021-10-15', 'M'),
		(NULL, 'Luca', 'Micaio', '2022-02-27', 'N');
        
INSERT INTO Insieme_squadre (fase, nome)
VALUES ('F-0', 'A'),
	   ('F-0', 'B'),
       ('F-2', NULL);

INSERT INTO Raggruppamento (insieme_squadre, squadra)
VALUES ('I-0','S-0'),
	   ('I-0','S-1'),
       ('I-0','S-2'),
	   ('I-0','S-3'),
       ('I-1','S-4'),
       ('I-1','S-5'),
       ('I-2','S-4'),
       ('I-2','S-5');
       
INSERT INTO Rosa (squadra, giocatore, numero_maglia)
VALUES ('S-0', 0, 0),
	   ('S-1', 1, 2),
       ('S-4', 0, 0),
       ('S-5', 0, 0);
		
LOAD DATA LOCAL INFILE './Popolamento/Giornata.csv'
INTO TABLE Giornata
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(codice, insieme_squadre, numero);

INSERT INTO Partita (giornata, giorno, ora, squadra_casa, squadra_ospite, arbitro, campo, gol_casa, gol_ospite)
VALUES ('G-0', '2023-08-19', '18:06', 'S-0', 'S-1', '2', 'C-0', 1, 0);

INSERT INTO Statistiche (partita, giocatore, gol, assist, ammonizioni)
VALUES ('P-0', '0', 1, 1, 0);

/*
 * SEZIONE DEDICATA ALLE INTERROGAZIONI
 */
 
# SELECT * FROM Torneo ORDER BY CAST(SUBSTRING(codice FROM 3) AS DECIMAL);
# SELECT * FROM Giocatore;
# SELECT * FROM Fase;
# SELECT * FROM Squadra;
# SELECT * FROM Insieme_squadre;
# SELECT * FROM Raggruppamento;
# SELECT * FROM tornei_terminati;
#  SELECT * FROM Giornata;
# SELECT * FROM Arbitro;




