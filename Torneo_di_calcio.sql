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
	indice		TINYINT UNSIGNED DEFAULT 1 NOT NULL,
                
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
	campo			VARCHAR(5) DEFAULT NULL,

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

CREATE TABLE IF NOT EXISTS Classifica (
	insieme_squadre		VARCHAR(7),
    giornata			VARCHAR(7),
    squadra				VARCHAR(8),
    vittorie			TINYINT UNSIGNED NOT NULL,
    pareggi				TINYINT UNSIGNED NOT NULL,
    sconfitte			TINYINT UNSIGNED NOT NULL,
    
    PRIMARY KEY (insieme_squadre, giornata, squadra),
    FOREIGN KEY (insieme_squadre)
		REFERENCES Insisme_squadre(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY (giornata)
		REFERENCES Giornata(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY (squadra)
		REFERENCES Squadra(codice)
        ON DELETE NO ACTION
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
	insieme_squadre	VARCHAR(7),
	squadra			VARCHAR(8),
    giocatore		SMALLINT UNSIGNED ,
    numero_maglia 	TINYINT UNSIGNED,
    
    PRIMARY KEY(insieme_squadre, squadra, giocatore),
	UNIQUE (squadra, numero_maglia),
	FOREIGN KEY (insieme_squadre)
		REFERENCES Insisme_squadre(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (squadra)
		REFERENCES Squadra(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY (giocatore)
		REFERENCES Giocatore(tessera)
        ON DELETE NO ACTION
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

CREATE TABLE IF NOT EXISTS Espulsione (
	giornata	VARCHAR(7),
	giocatore	SMALLINT UNSIGNED,
    
    PRIMARY KEY(giornata, giocatore),
    FOREIGN KEY(giornata)
		REFERENCES Giornata(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY(giocatore)
		REFERENCES Giocatore(tessera)
        ON DELETE NO ACTION
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
 * La seguente vista mostra l'elenco delle partite per ogni torneo, 
 * comprese le squadre che giocano la suddetta partita.
 */
 CREATE VIEW partite_torneo 
 (torneo, fase, insieme, giornata, numero_giornata, partita, squadra_casa, squadra_ospite) AS
 SELECT torneo, fase, insieme, giornata, numero_giornata, partita, squadra_casa, squadra_ospite FROM 
 (SELECT F.torneo AS torneo, F.codice AS fase, I.codice AS insieme FROM Fase F, Insieme_squadre I WHERE F.codice = I.fase) AS TFI 
 NATURAL JOIN
 (SELECT G.insieme AS insieme, G.codice AS giornata, G.numero AS numero_giornata, P.codice AS partita, P.squadra_casa, P.squadra_ospite FROM Giornata G, Partita P WHERE P.giornata = G.codice);

/*
 * SEZIONE DEDICATA AI TRIGGER
 * La sezione successiva definisce i trigger per il controllo 
 * dei vincoli non esprimibili nella creazione delle tabelle.
 * Per ogni tabella è stato preferito definire massimo due trigger, uno per 
 * l'inserimento e l'altro per la modifica, al fine di agevolare il lettore.
 * Questo rende lo script meno frastagliato ma costringe ad una struttura
 * interna non sempre elegante (esempio, prima vengono inserite tutte le
 * dichiarazioni di variabili utili per tutti i controlli da eseguire 
 * nel trigger e poi i vari controlli).
 * I trigger relativi agli inserimenti condividono una sezione per il 
 * controllo del formato del codice. Non è stato possibile implementare
 * una procedura unica per tutti i trigger per limitazioni del linguaggio:
 * non è possibile utilizzare in questi i meccanismi dinamici di SQL
 * (es. prepared functions) per il riconoscimento della tabella da 
 * cui eseguire la ricerca degli indici del codice.
 * I trigger per gli inserimenti quindi controllano il formato del 
 * codice e, qualora non sia corretto, lo assegnano, individuando l'indice 
 * minimo tra quelli disponibili. Non è, quindi, detto che le istanze  
 * cronologicamente successive abbiano codice maggiore.
 */
 
DELIMITER $$
CREATE TRIGGER TR_INS_Torneo BEFORE INSERT ON Torneo
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127); 
    
    -- Controllo formato codice ed eventuale asseganzione
	IF NEW.codice NOT LIKE 'T-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Torneo HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Torneo)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Torneo HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Torneo)) AS idx_libero_next;
        SET NEW.codice = CONCAT('T-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
    END IF;
END$$

CREATE TRIGGER TR_UPD_Torneo BEFORE UPDATE ON Torneo
FOR EACH ROW
BEGIN
	DECLARE genere_squadra 	ENUM('M','F','N');
    
    -- Controllo che il genere del torneo sia consictente con il genere delle squadre
    IF OLD.genere <> NEW.genere
    THEN
		SELECT genere INTO genere_squadra FROM Squadra WHERE codice = (SELECT squadra FROM squadra_iscrizioni WHERE torneo = OLD.codice LIMIT 1);
        IF genere_squadra <> NEW.genere
		THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere delle squadre assegante al torneo devono essere concordi.', MYSQL_ERRNO='5000';
        END IF;
    END IF;
    
    -- Controllo formato codice
    IF NEW.codice NOT LIKE 'T-_%' OR NEW.codice IS NULL 
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Formato codice non accettabile. Il codice inserito come nuovo codice non rispetta il formato per il campo.", MYSQL_ERRNO='5009';
	END IF;
END $$

CREATE TRIGGER TR_INS_Fase BEFORE INSERT ON Fase
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
    
    -- Controllo formato codice
	IF NEW.codice NOT LIKE 'F-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Fase HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Fase)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Fase HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Fase)) AS idx_libero_next;
        SET NEW.codice = CONCAT('F-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
	END IF;
END$$

CREATE TRIGGER TR_UPD_Fase BEFORE UPDATE ON Fase
FOR EACH ROW
BEGIN
	-- Controllo formato codice
    IF NEW.codice NOT LIKE 'F-_%' OR NEW.codice IS NULL 
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Formato codice non accettabile. Il codice inserito come nuovo codice non rispetta il formato per il campo.", MYSQL_ERRNO='5009';
	END IF;
END $$

CREATE TRIGGER TR_INS_Insieme_squadre BEFORE INSERT ON Insieme_squadre
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
    
     -- Controllo formato codice
	IF NEW.codice NOT LIKE 'I-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Insieme_squadre HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Insieme_squadre)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Insieme_squadre HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Insieme_squadre)) AS idx_libero_next;
        SET NEW.codice = CONCAT('I-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
	END IF;
END$$

CREATE TRIGGER TR_UPD_Insieme_squadre BEFORE UPDATE ON Insieme_squadre
FOR EACH ROW
BEGIN
	-- Controllo formato codice
    IF NEW.codice NOT LIKE 'I-_%' OR NEW.codice IS NULL 
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Formato codice non accettabile. Il codice inserito come nuovo codice non rispetta il formato per il campo.", MYSQL_ERRNO='5009';
	END IF;
END $$

CREATE TRIGGER TR_INS_Campo BEFORE INSERT ON Campo
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
    
	-- Controllo formato codice
	IF NEW.codice NOT LIKE 'C-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Campo HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Campo)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Campo HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Campo)) AS idx_libero_next;
        SET NEW.codice = CONCAT('C-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
	END IF;
END$$

CREATE TRIGGER TR_UPD_Campo BEFORE UPDATE ON Campo
FOR EACH ROW
BEGIN
	-- Controllo formato codice
    IF NEW.codice NOT LIKE 'C-_%' OR NEW.codice IS NULL 
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Formato codice non accettabile. Il codice inserito come nuovo codice non rispetta il formato per il campo.", MYSQL_ERRNO='5009';
	END IF;
END $$

CREATE TRIGGER TR_INS_Squadra BEFORE INSERT ON Squadra
FOR EACH ROW  
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
    
	-- Controllo formato codice
	IF NEW.codice NOT LIKE 'S-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Squadra HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Squadra)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Squadra HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Squadra)) AS idx_libero_next;
        SET NEW.codice = CONCAT('S-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
	END IF;
END$$

CREATE TRIGGER TR_UPD_Squadra BEFORE UPDATE ON Squadra
FOR EACH ROW
BEGIN
	DECLARE genere_torneo 			ENUM('M','F','N');
    DECLARE genere_giocatore 		ENUM('M','F','N');
    DECLARE gen_giocatore_cursor 	CURSOR FOR 
		SELECT genere FROM Giocatore WHERE codice IN (SELECT giocatore FROM Rosa WHERE squadra=OLD.codice);
	DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;
    
	-- Controllo formato codice
    IF NEW.codice NOT LIKE 'S-_%' OR NEW.codice IS NULL 
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Formato codice non accettabile. Il codice inserito come nuovo codice non rispetta il formato per il campo.", MYSQL_ERRNO='5009';
	END IF;
        
	-- Controllo genere concordante tra Squadra e Torneo
    SELECT genere INTO genere_torneo FROM Torneo WHERE codice = (SELECT torneo FROM squadra_iscrizioni WHERE squadra = OLD.codice LIMIT 1);
    IF NEW.genere <> genere_torneo
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
	-- Controllo genere compatibile tra Giocatore e Squadra
    IF NEW.genere <> 'N'
    THEN
		OPEN gen_giocatore_cursor;
		check_gen_giocatore: LOOP
			FETCH gen_giocatore_cursor INTO genere_giocatore;
			IF genere_giocatore <> NEW.genere		-- Squadre miste accettano giocatori di ogni genere
			THEN
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
				LEAVE check_gen_giocatore;
			END IF;
		END LOOP;
	END IF;
END $$

CREATE TRIGGER TR_INS_Ragguppamento BEFORE INSERT ON Raggruppamento
FOR EACH ROW
BEGIN
	DECLARE genere_squadra 		ENUM('M','F','N');
    DECLARE genere_torneo 		ENUM('M','F','N');
    DECLARE errmsg				VARCHAR(127);
    DECLARE warnmsg				VARCHAR(127);
    DECLARE giocatore_check		VARCHAR(8);
    DECLARE giocatore_cursor	CURSOR FOR 
		SELECT giocatore FROM Rosa WHERE squadra = NEW.squadra;
	DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;
    
    -- Controllo genere concordante tra Squadra e Torneo
	SELECT genere INTO genere_squadra FROM Squadra WHERE codice = NEW.squadra;
    SELECT genere INTO genere_torneo FROM Torneo WHERE codice = 
		(SELECT torneo FROM squadra_iscrizioni WHERE insieme = NEW.insieme_squadre);
    IF genere_squadra <> genere_torneo
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
    -- Controllo che la squadra non stia gia partecipando alla fase
    IF (NEW.squadra IN 
		(SELECT isc.squadra FROM squadra_iscrizioni AS isc WHERE isc.fase IN 
			(SELECT I.fase FROM Insieme_squadre I WHERE I.codice = NEW.insieme_squadre)))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Squadra già partecipante alla fase.', MYSQL_ERRNO='5004';
    END IF;
    
    -- Controllo che le squadre abbiano tutti giocatori differenti
    OPEN giocatore_cursor;
    check_giocatore_gia_iscritto: LOOP -- leave sottointesa: uscita con la exit dell'handler al termine dei fetch del cursore
		FETCH giocatore_cursor INTO giocatore_check;
        IF (SELECT COUNT(giocatore) FROM (SELECT R.giocatore FROM Rosa R WHERE R.giocatore = giocatore_check AND R.insieme_squadre = NEW.insieme_squadre) giocatore_times)  <> 1
		THEN
			SET errmsg = CONCAT("Giocatore già presente nell'insieme di squadre. Il giocatore ", giocatore_check, " è già presente nel'insieme ", NEW.insieme_squadre);
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errmsg, MYSQL_ERRNO = '5008';
            LEAVE check_giocatore_gia_iscritto;
        END IF;
	END LOOP;
END $$

CREATE TRIGGER TR_UPD_Raggruppamento BEFORE UPDATE ON Raggruppamento
FOR EACH ROW
BEGIN
	DECLARE genere_squadra 		ENUM('M','F','N');
    DECLARE genere_torneo 		ENUM('M','F','N');
    DEClARE warnmsg 			VARCHAR(127);
    DECLARE errmsg				VARCHAR(127);
	DECLARE giocatore_check		VARCHAR(8);
    DECLARE giocatore_cursor	CURSOR FOR 
		SELECT giocatore FROM Rosa WHERE squadra = NEW.squadra;
	DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;
    
    -- Controllo genere concordante tra Squadra e Torneo
	SELECT genere INTO genere_squadra FROM Squadra WHERE codice = NEW.squadra;
    SELECT genere INTO genere_torneo FROM Torneo WHERE codice = 
		(SELECT torneo FROM squadra_iscrizioni WHERE insieme = NEW.insieme_squadre);
    IF genere_squadra <> genere_torneo
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
	-- Controllo che la squadra non stia gia partecipando alla fase
    IF (NEW.squadra IN 
		(SELECT isc.squadra FROM squadra_iscrizioni AS isc WHERE isc.fase IN 
			(SELECT I.fase FROM Insieme_squadre I WHERE I.codice = NEW.insieme_squadre)))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Squadra già partecipante alla fase.', MYSQL_ERRNO='5004';
    END IF;
    
    -- Controllo che le squadre abbiano tutti giocatori differenti
    OPEN giocatore_cursor;
    check_giocatore_gia_iscritto: LOOP -- leave sottointesa: uscita con la exit dell'handler al termine dei fetch del cursore
		FETCH giocatore_cursor INTO giocatore_check;
        IF (SELECT COUNT(giocatore) FROM (SELECT R.giocatore FROM Rosa R WHERE R.giocatore = giocatore_check AND R.insieme_squadre = NEW.insieme_squadre) giocatore_times)  <> 1
		THEN
			SET errmsg = CONCAT("Giocatore già presente nell'insieme di squadre. Il giocatore ", giocatore_check, " è già presente nel'insieme ", NEW.insieme_squadre);
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errmsg, MYSQL_ERRNO = '5008';
            LEAVE check_giocatore_gia_iscritto;
        END IF;
	END LOOP;
END $$

CREATE TRIGGER TR_INS_Giornata BEFORE INSERT ON Giornata
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(127);
    DECLARE idx_prev_libero INT;
	DECLARE idx_next_libero INT;

    -- Controllo formato codice
	IF NEW.codice NOT LIKE 'G-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT (CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1) AS idx FROM Giornata HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Giornata)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT (CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1) AS idx FROM Giornata HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Giornata)) AS idx_libero_next;
        SET NEW.codice = CONCAT('G-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
	END IF;
END$$

CREATE TRIGGER TR_UPD_Giornata BEFORE UPDATE ON Giornata
FOR EACH ROW
BEGIN
	DECLARE n_partite 	SMALLINT UNSIGNED;
    DECLARE n_squadre 	SMALLINT UNSIGNED;
    DEClARE warnmsg 	VARCHAR(127);
    
	-- Controllo formato codice
    IF NEW.codice NOT LIKE 'G-_%' OR NEW.codice IS NULL 
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Formato codice non accettabile. Il codice inserito come nuovo codice non rispetta il formato per il campo.", MYSQL_ERRNO='5009';
	END IF;
END $$

CREATE TRIGGER TR_INS_Classifica BEFORE INSERT ON Classifica
FOR EACH ROW
BEGIN
	-- Controllo che squadra appartenga all'insieme di squadre
    IF (NEW.squadra NOT IN (SELECT squadra FROM Raggruppamento WHERE insieme = NEW.insieme))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Squadra non partecipante alla fase nell'insieme specificato", MYSQL_ERRNO='5007' ;
    END IF;
END $$

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
    
     -- Controllo formato tessera
	IF NEW.tessera IS NULL 
	THEN 
		SET NEW.tessera = COALESCE((SELECT MAX(tessera)+1 FROM tesseramenti), 0);
	END IF;
END$$

CREATE TRIGGER TR_UPD_Giocatore BEFORE UPDATE ON Giocatore
FOR EACH ROW
BEGIN
	DECLARE genere_squadra ENUM('M', 'F', 'N');
    DECLARE gen_squad_cursor CURSOR FOR 
		SELECT genere FROM Squadra WHERE codice IN
			(SELECT squadra FROM Rosa WHERE giocatore = OLD.tessera);
	DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;
    
	-- Controllo genere compatibile tra Giocatore e Squadra
    OPEN gen_squad_cursor;
    check_gen_squad: LOOP
		FETCH gen_squad_cursor INTO genere_squadra;
		IF genere_squadra <> 'N' AND genere_squadra <> NEW.genere		-- Squadre miste accettano giocatori di ogni genere
		THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
            LEAVE check_gen_squad;
		END IF;
	END LOOP;
END $$

CREATE TRIGGER TR_INS_Rosa BEFORE INSERT ON Rosa
FOR EACH ROW
BEGIN
	DECLARE genere_squadra	 ENUM('M','F','N');
    DECLARE genere_giocatore ENUM('M','F','N');
    
	-- Controllo numero_maglia appartenente al dominio 
    IF NEW.numero_maglia > 99		-- Data la tipologia UNSIGNED del dato non occorre il controllo: (... < 0)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Numero maglia non accettabile. I numeri di maglia devono essere interni compresi tra 0 e 99 inclusi.', MYSQL_ERRNO='5002';
	END IF;
    
	-- Controllo genere compatibile tra Giocatore e Squadra
	SELECT Squadra.genere INTO genere_squadra FROM Squadra WHERE Squadra.codice = NEW.squadra;
    SELECT Giocatore.genere INTO genere_giocatore FROM Giocatore WHERE Giocatore.tessera = NEW.Giocatore;
    IF genere_squadra <> 'N' AND genere_squadra <> genere_giocatore		-- Squadre miste accettano giocatori di ogni genere
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
    -- Controllo che le squadre dell'insieme abbiano tutti giocatori differenti
	IF (SELECT ALL COUNT(giocatore) FROM Rosa WHERE insieme_squadre = NEW.insieme_squadre AND giocatore = NEW.giocatore) <> 1
	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Giocatore già presente nell'insieme di squadre.", MYSQL_ERRNO = '5008';
	END IF;
END $$

CREATE TRIGGER TR_UPD_Rosa BEFORE UPDATE ON Rosa
FOR EACH ROW
BEGIN
	DECLARE genere_squadra	 ENUM('M','F','N');
    DECLARE genere_giocatore ENUM('M','F','N');
    
	-- Controllo numero_maglia appartenente al dominio 
    IF NEW.numero_maglia > 99		-- Data la tipologia UNSIGNED del dato non occorre il controllo: (... < 0)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Numero maglia non accettabile. I numeri di maglia devono essere interni compresi tra 0 e 99 inclusi.', MYSQL_ERRNO='5002';
	END IF;
    
	-- Controllo genere compatibile tra Giocatore e Squadra
	SELECT Squadra.genere INTO genere_squadra FROM Squadra WHERE Squadra.codice = NEW.squadra;
    SELECT Giocatore.genere INTO genere_giocatore FROM Giocatore WHERE Giocatore.tessera = NEW.Giocatore;
    IF genere_squadra <> 'N' AND genere_squadra <> genere_giocatore		-- Squadre miste accettano giocatori di ogni genere
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
	-- Controllo che le squadre abbiano tutti giocatori differenti
    IF (SELECT ALL COUNT(giocatore) FROM Rosa WHERE insieme_squadre = NEW.insieme_squadre AND giocatore = NEW.giocatore) <> 0
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Giocatore già presente nell'insieme di squadre.", MYSQL_ERRNO = '5008';
	END IF;
END $$

CREATE TRIGGER TR_INS_Arbitro BEFORE INSERT ON Arbitro
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(127);
	IF NEW.tessera IS NULL 
	THEN 
		SET NEW.tessera = COALESCE((SELECT MAX(tessera) FROM tesseramenti) + 1, 0);
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
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Squadre uguali. Le partite devono essere formate da due squadre distinte.", MYSQL_ERRNO=5003;
    END IF;
    
    -- Controllo formato codice
	IF NEW.codice NOT LIKE 'P-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Partita HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Partita)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Partita HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Partita)) AS idx_libero_next;
        SET NEW.codice = CONCAT('P-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
	END IF;
END$$

CREATE TRIGGER TR_UPD_Partita BEFORE UPDATE ON Partita
FOR EACH ROW
BEGIN
	DECLARE somma_gol_casa 		TINYINT UNSIGNED;
	DECLARE somma_gol_ospite	TINYINT UNSIGNED;
    DECLARE errmsg				VARCHAR(127);

	-- Controllo formato codice
    IF NEW.codice NOT LIKE 'P-_%' OR NEW.codice IS NULL 
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Formato codice non accettabile. Il codice inserito come nuovo codice non rispetta il formato per il campo.", MYSQL_ERRNO='5009';
	END IF;
    
    -- Controllo vincolo: squadre giocanti diverse
    IF NEW.squadra_casa = NEW.squadra_ospite
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Squadre uguali. Le partite devono essere formate da due squadre distinte.", MYSQL_ERRNO=5003;
    END IF;
       
    -- Controllo che somma dei gol corrisponda a punteggio partita
    SELECT SUM(gol) INTO somma_gol_casa FROM Statistiche WHERE partita = NEW.codice AND giocatore IN
		(SELECT giocatore FROM Rosa WHERE squadra = NEW.squadra_casa);
    SELECT SUM(gol) INTO somma_gol_ospite FROM Statistiche WHERE partita = NEW.codice AND giocatore IN
		(SELECT giocatore FROM Rosa WHERE squadra = NEW.squadra_ospite);    
    IF somma_gol_casa <> NEW.gol_casa OR somma_gol_ospite <> NEW.gol_ospite
    THEN
		SET errmsg = CONCAT("Punteggio inconsistente. Il punteggio della partita non corrisponde alla somma dei gol: ", CONCAT(NEW.gol_casa, '-', NEW.gol_ospite), " invece di ", CONCAT(somma_gol_casa, '-', somma_gol_ospite));
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errnmsg, MYSQL_ERRNO='5005';
	END IF;
END $$

CREATE TRIGGER TR_INS_Statistiche BEFORE INSERT ON Statistiche
FOR EACH ROW
BEGIN 
	DECLARE errmsg 					VARCHAR(127);
    DECLARE squadra_casa			VARCHAR(8);
    DECLARE somma_gol 				TINYINT UNSIGNED;
    DECLARE gol_squadra_giocatore 	TINYINT UNSIGNED;
    DECLARE warnmsg					VARCHAR(127);
    DECLARE espulsioni_mancanti		INT UNSIGNED;
    DECLARE giornata_inizio_esp		INT UNSIGNED;
    DECLARE ultima_giornata			INT UNSIGNED;
    
    -- Controllo ammonizioni appartenenti a {0,1,2}
    IF NEW.ammonizioni NOT IN (0,1,2)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Numero ammonizioni fuori dal dominio {0, 1, 2}.", MYSQL_ERRNO=5001;
    END IF;
    
    -- Controllo espulsioni pari ad almeno 1 se ammonizioni pari a 2
    IF NEW.ammonizioni = 2 AND NEW.espulsione.giornate < 1
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Giornate espulsione insufficienti dato ammonizioni pari a 2.", MYSQL_ERRNO='5010';
    END IF;
    
    -- Controllo che somma dei gol corrisponda a punteggio partita
	SELECT SUM(gol)+NEW.gol INTO somma_gol FROM Statistiche WHERE partita = NEW.partita AND giocatore IN 					
		(SELECT DISTINCT giocatore FROM Rosa WHERE squadra IN (SELECT squadra FROM Rosa WHERE giocatore = NEW.giocatore));
	SELECT squadra_casa INTO squadra_casa FROM Partita WHERE codice = NEW.partita;
	SELECT IF(squadra_casa IN (SELECT squadra FROM Rosa WHERE giocatore = NEW.giocatore), gol_casa, gol_ospite) 	-- la condizione che la squadra di casa sia una di quelle del giocatore è sufficiente dato il vincolo di singola partecipazione del giocatore ad un insieme di squadra 
		INTO gol_squadra_giocatore FROM Partita WHERE codice = NEW.partita;
    IF somma_gol <> gol_squadra_giocatore
    THEN
		SET errmsg = CONCAT("Punteggio inconsistente. Il punteggio della partita non corrisponde alla somma dei gol: (somma gol) - (gol squadra) = ", (somma_gol - gol_squadra_giocatore));
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errmsg, MYSQL_ERRNO='5005';
	END IF;
        
    -- Inserimento espulsioni
    -- Nel caso in cui le giornate di espulsione siano maggiori di zero allora,
    -- viene eseguito un ciclo che aggiunge ad Espulsione istanze coerenti fintantoché 
    -- o sono state inserite tutte le giornate di espulsione oppure si è giurni all'ultima 
    -- giornata della fase per l'insieme.
    IF NEW.espulsione_giornate <> 0
    THEN
		SET espulsioni_aggiunte = 0;
        SELECT Giornata.numero INTO giornata_inizio_espulsione FROM Giornata WHERE Giornata.codice = (SELECT Partita.giornata FROM Partita WHERE Partita.codice = NEW.partita);
        SELECT MAX(numero) INTO ultima_giornata FROM partite_torneo WHERE insieme = (SELECT insieme FROM partite_torneo WHERE partita = NEW.partita);
		insert_espulsioni: WHILE (espulsioni_aggiunte <> NEW.espulsione_giornate OR giornata_inizio_espulsione + espulsioni_aggiunte < ultima_giornata)		
        DO
			SET espulsioni_aggiunte = espulsioni_aggiunte +1;
			INSERT INTO Espulsione (giornata, giocatore) 
            VALUES ((SELECT giornata FROM partite_torneo WHERE numero = giornata_inizio_espulsione + espulsioni_aggiunte 
				AND insieme = (SELECT insieme FROM partite_torneo WHERE partita = NEW.partita)),
                NEW.giocatore);
        END WHILE;
	END IF;		
END $$

CREATE TRIGGER TR_UPD_Statistiche BEFORE UPDATE ON Statistiche
FOR EACH ROW
BEGIN
	DECLARE squadra_casa			VARCHAR(8);
	DECLARE somma_gol 				TINYINT UNSIGNED;
    DECLARE gol_squadra_giocatore 	TINYINT UNSIGNED;
    DECLARE errmsg					VARCHAR(127);
    
	-- Controllo ammonizioni appartenenti a {0,1,2}
    IF NEW.ammonizioni NOT IN (0,1,2)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Numero ammonizioni fuori dal dominio {0, 1, 2}.", MYSQL_ERRNO=5001;
    END IF;
    
    -- Controllo espulsioni pari ad almeno 1 se ammonizioni pari a 2
    IF NEW.ammonizioni = 2 AND NEW.espulsione.giornate < 1
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Giornate espulsione insufficienti dato ammonizioni pari a 2.", MYSQL_ERRNO='5010';
    END IF;
    
    -- Controllo che somma dei gol corrisponda a punteggio partita
	SELECT IF(OLD.partita = NEW.partita, SUM(gol)-OLD.gol+NEW.gol, SUM(gol)+NEW.gol) INTO somma_gol FROM Statistiche WHERE partita = NEW.partita AND giocatore IN 
		(SELECT DISTINCT giocatore FROM Rosa WHERE squadra IN (SELECT squadra FROM Rosa WHERE giocatore = NEW.giocatore));
	SELECT squadra_casa INTO squadra_casa FROM Partita WHERE codice = NEW.partita;
	SELECT IF(squadra_casa IN (SELECT squadra FROM Rosa WHERE giocatore = NEW.giocatore), gol_casa, gol_ospite) 	-- la condizione che la squadra di casa sia una di quelle del giocatore è sufficiente dato il vincolo di singola partecipazoine del giocatore ad un insieme di squadre 
		INTO gol_squadra_giocatore FROM Partita WHERE codice = NEW.partita;
    IF somma_gol <> gol_squadra_giocatore
    THEN
		SET errmsg = CONCAT("Punteggio inconsistente. Il punteggio della partita non corrisponde alla somma dei gol: (somma gol) - (gol squadra) = ", (somma_gol - gol_squadra_giocatore));
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errmsg, MYSQL_ERRNO='5005';
	END IF;
END$$

CREATE TRIGGER TR_INS_Espulsione BEFORE INSERT ON Espulsione
FOR EACH ROW
BEGIN
	-- Controllo che il giocatore partecipi all'insieme
    IF (NEW.giocatore NOT IN (SELECT giocatore FROM Rosa WHERE insieme_squadre = (SELECT Giornata.insieme_squadre FROM Giornata WHERE Giornata.codice = NEW.giornata)))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Giocatore non partecipante all'insieme di squadre proprio della giornata inserita.", MYSQL_ERRNO = '5006';
    END IF;
END $$

CREATE TRIGGER TR_UPD_Espulsione BEFORE UPDATE ON Espulsione
FOR EACH ROW
BEGIN
	-- Controllo che il giocatore partecipi all'insieme
    IF (NEW.giocatore NOT IN (SELECT giocatore FROM Rosa WHERE insieme_squadre = (SELECT Giornata.insieme_squadre FROM Giornata WHERE Giornata.codice = NEW.giornata)))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Giocatore non partecipante all'insieme di squadre proprio della giornata inserita.", MYSQL_ERRNO = '5006';
    END IF;
END $$

DELIMITER ;
/*
 * SEZIONE DEDICATA AGLI INSERIMENTI
 */

-- Inserimento manuale da script (tabella Torneo)
INSERT INTO Torneo (nome, tipologia, genere, edizione)
VALUES	('Firenze Inverno',	'7','N',1),
		('Firenze Estate',	'7','N',1);
            
-- Inserimento tramite file non standard
LOAD DATA LOCAL INFILE './Popolamento/Fase.in'
INTO TABLE Fase
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '+'
IGNORE 3 LINES
(codice, nome, modalita, scontri, torneo);

-- I successivi inserimenti saranno tutti importati da file nel formato standard CSV
LOAD DATA LOCAL INFILE './Popolamento/Insieme_squadre.csv'
INTO TABLE Insieme_squadre
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(fase, nome);

LOAD DATA LOCAL INFILE './Popolamento/Campo.csv'
INTO TABLE Campo
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(codice, nome, telefono, comune, via, civico);

LOAD DATA LOCAL INFILE './Popolamento/Squadra.csv'
INTO TABLE Squadra
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(codice, nome, tipologia, genere, colori, campo);

LOAD DATA LOCAL INFILE './Popolamento/Giocatore.csv'
INTO TABLE Giocatore
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(tessera, nome, cognome, genere, data);
        
LOAD DATA LOCAL INFILE './Popolamento/Arbitro.csv'
INTO TABLE Arbitro
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(tessera, nome, cognome, genere, data);

LOAD DATA LOCAL INFILE './Popolamento/Raggruppamento.csv'
INTO TABLE Raggruppamento
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(insieme_squadre, squadra);
       
LOAD DATA LOCAL INFILE './Popolamento/Rosa.csv'
INTO TABLE Rosa
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(squadra, giocatore, numero_maglia);

-- A causa dei controlli nei trigger di Giornata gli inserimenti di queste devono 
-- essere successivi agli inserimenti di Raggruppamento, altrimenti il logaritmo
-- ivi presente genera un errore.
LOAD DATA LOCAL INFILE './Popolamento/Giornata.csv'
INTO TABLE Giornata
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(codice, insieme_squadre, numero);

LOAD DATA LOCAL INFILE './Popolamento/Partita.csv'
INTO TABLE Partita
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(codice, giornata, giorno, ora, squadra_casa, squadra_ospite, arbitro, campo, gol_casa, gol_ospite);



/*
 * La procedura successiva occorre per l'inserimento di Statistiche.
 * Alcuni inserimenti di questa tabella vengono inseriti tramite questa
 * per mostrarne il funzionamento.
 */

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
# SELECT * FROM Giornata;
# SELECT * FROM Arbitro;
# SELECT * FROM Campo;