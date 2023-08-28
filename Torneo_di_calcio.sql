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
    UNIQUE (torneo, indice),
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
		REFERENCES Insieme_squadre(codice)
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
	UNIQUE (insieme_squadre, squadra, numero_maglia),
	FOREIGN KEY (insieme_squadre)
		REFERENCES Insieme_squadre(codice)
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

CREATE TABLE IF NOT EXISTS Partita_giocata (
	partita		VARCHAR(9) PRIMARY KEY,
	gol_casa	TINYINT UNSIGNED NOT NULL,
    gol_ospite	TINYINT UNSIGNED NOT NULL,
    
    FOREIGN KEY (partita)
    REFERENCES Partita(codice)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Statistiche(
	giocatore			SMALLINT UNSIGNED NOT NULL,
    partita_giocata		VARCHAR(9) NOT NULL,
    gol					TINYINT UNSIGNED DEFAULT 0 NOT NULL,
    assist				TINYINT UNSIGNED DEFAULT 0 NOT NULL,
	ammonizioni			TINYINT UNSIGNED DEFAULT 0 NOT NULL,
	espulsione_giornate	TINYINT UNSIGNED DEFAULT 0 NOT NULL,
    
    PRIMARY KEY (giocatore, partita_giocata),
    FOREIGN KEY(giocatore)
		REFERENCES Giocatore(tessera)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY(partita_giocata)
		REFERENCES Partita_giocata(partita)
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
(SELECT codice, nome, edizione, genere, tipologia FROM Torneo WHERE codice IN
	(SELECT torneo FROM Fase WHERE codice IN 
		(SELECT fase FROM Insieme_squadre WHERE codice IN 
			(SELECT insieme_squadre FROM Giornata WHERE codice IN												-- Giornate con almeno una partita e che ha tutte le partite già giocate.
				(SELECT giornata FROM Partita)																	-- Tutte le partite
			AND codice NOT IN
				(SELECT giornata FROM Partita WHERE codice NOT IN (SELECT partita FROM Partita_giocata))))));	-- Partite non ancora giocate, ovvero partite che non hanno un'istanza corrispondente in Partita_giocata
                
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
 (SELECT G.insieme_squadre AS insieme, G.codice AS giornata, G.numero AS numero_giornata, P.codice AS partita, P.squadra_casa, P.squadra_ospite FROM Giornata G, Partita P WHERE P.giornata = G.codice) AS GP;


/*
 * La successiva procedura recupera i valori di vittorie, pareggi e sconfitte
 * in Clasifica della giornata precedente a quella indicata come parametro
 * per squadra ed insieme specificati e li inserisce nei parametri di output.
 * Questa funzione occorre nell'inserimeto, modifica e rimosione di partite giocate 
 * per l'aggioramento della classifica.
 */
DELIMITER $$
CREATE PROCEDURE risultati_giornata_precedente (IN insieme VARCHAR(7), IN giornata VARCHAR(7), IN numero_giornata TINYINT UNSIGNED, IN squadra VARCHAR(8), 
OUT vittorie TINYINT UNSIGNED, OUT pareggi TINYINT UNSIGNED, OUT sconfitte TINYINT UNSIGNED)
BEGIN
	IF numero_giornata = 1
    THEN SELECT 0,0,0 INTO vittorie,pareggi,sconfitte;
    ELSE
		SELECT C.vittorie, C.pareggi, C.sconfitte INTO vittorie, pareggi, sconfitte FROM Classifica C WHERE
			C.insieme_squadre = insieme AND 
			C.giornata = (SELECT G.codice FROM Giornata G WHERE G.insieme_squadre = insieme AND G.numero = numero_giornata-1) AND 
			C.squadra = squadra;
	END IF;
END $$
DELIMITER ;

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
		(SELECT DISTINCT torneo FROM squadra_iscrizioni WHERE insieme = NEW.insieme_squadre);
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
    IF NEW.squadra NOT IN (SELECT squadra FROM Raggruppamento WHERE insieme_squadre = NEW.insieme_squadre)
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
	IF (SELECT ALL COUNT(giocatore) FROM Rosa WHERE insieme_squadre = NEW.insieme_squadre AND giocatore = NEW.giocatore) > 1
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
END $$

CREATE TRIGGER TR_INS_Partita_giocata AFTER INSERT ON Partita_giocata
FOR EACH ROW
BEGIN
	DECLARE insieme			VARCHAR(7);
    DECLARE giornata		VARCHAR(7);
    DECLARE numero_giornata TINYINT UNSIGNED;
    DECLARE squadra_casa	VARCHAR(8);
    DECLARE squadra_ospite	VARCHAR(8);
    DECLARE vittorie		TINYINT UNSIGNED;
    DECLARE pareggi			TINYINT UNSIGNED;
    DECLARE sconfitte		TINYINT UNSIGNED;
    
    -- Aggiornamento classifica
    SELECT PT.insieme,PT.giornata,PT.numero_giornata,PT.squadra_casa,PT.squadra_ospite 
    INTO insieme,giornata,numero_giornata,squadra_casa,squadra_ospite 
    FROM partite_torneo PT WHERE partita = NEW.partita;
    -- Squadra casa
    CALL risultati_giornata_precedente(insieme, giornata, numero_giornata, squadra_casa, vittorie, pareggi, sconfitte);
    IF NEW.gol_casa < NEW.gol_ospite 
	THEN SET sconfitte = sconfitte +1;
    ELSEIF NEW.gol_casa > NEW.gol_ospite
    THEN SET vittorie = vittorie +1;
    ELSE SET pareggi = pareggi +1;
    END IF;
 	INSERT INTO Classifica (insieme_squadre, giornata, squadra, vittorie, pareggi, sconfitte) 		-- Si esegue un inserimento alla volta per risparmiare dichiarazioni di variabili
    VALUES (insieme, giornata, squadra_casa, vittorie, pareggi, sconfitte);
    -- Squadra ospite
    CALL risultati_giornata_precedente(insieme, giornata, numero_giornata, squadra_ospite, vittorie, pareggi, sconfitte);
	IF NEW.gol_casa > NEW.gol_ospite 
	THEN SET sconfitte = sconfitte +1;
    ELSEIF NEW.gol_casa < NEW.gol_ospite
    THEN SET vittorie = vittorie +1;
    ELSE SET pareggi = pareggi +1;
    END IF;
	INSERT INTO Classifica (insieme_squadre, giornata, squadra, vittorie, pareggi, sconfitte) 
	VALUES (insieme, giornata, squadra_ospite, vittorie, pareggi, sconfitte);
END $$


CREATE TRIGGER TR_UPD_Partita_giocata BEFORE UPDATE ON Partita_giocata
FOR EACH ROW
BEGIN
	DECLARE insieme					VARCHAR(7);
    DECLARE numero_giornata 		TINYINT UNSIGNED;
    DECLARE squadra_casa			VARCHAR(8);
    DECLARE squadra_ospite			VARCHAR(8);
    DECLARE casa_vittorie_add 		TINYINT;
    DECLARE casa_pareggi_add 		TINYINT;
    DECLARE casa_sconfitte_add 		TINYINT;
    DECLARE ospite_vittorie_add 	TINYINT;
    DECLARE ospite_pareggi_add		TINYINT;
    DECLARE ospite_sconfitte_add	TINYINT;
    
    SELECT PT.insieme, PT.numero_giornata INTO insieme, numero_giornata FROM partite_torneo PT WHERE PT.partita = NEW.partita;
    SELECT squadra_casa, squadra_ospite INTO squadra_casa, squadra_ospite FROM Partita WHERE codice = NEW.partita;
    SELECT 0,0,0,0,0,0 INTO casa_vittorie_add, casa_pareggi_add, casa_sconfitte_add, ospite_vittorie_add, ospite_pareggi_add, ospite_sconfitte_add;
    
    IF OLD.gol_casa < OLD.gol_ospite 
	THEN SET casa_sconfitte_add = -1;
         SET ospite_vittorie_add = -1;
	ELSEIF OLD.gol_casa <> OLD.gol_ospite
	THEN SET casa_pareggi_add = -1;
         SET ospite_pareggi_add = -1;
	ELSE SET casa_vittorie_add = -1;
         SET ospite_sconfitte_add = -1;
	END IF;
    
    IF NEW.gol_casa < NEW.gol_ospite 
	THEN SET casa_sconfitte_add = casa_sconfitte_add +1;
         SET ospite_vittorie_add = ospite_vittorie_add + 1;
	ELSEIF OLD.gol_casa <> OLD.gol_ospite
	THEN SET casa_pareggi_add = casa_pareggi_add +1;
         SET ospite_pareggi_add = ospite_pareggi_add +1;
	ELSE SET casa_vittorie_add = casa_vittorie_add +1;
         SET ospite_sconfitte_add = ospite_sconfitte_add +1;
	END IF;
    	
	UPDATE Classifica C SET C.vittorie = (C.vittorie + casa_vittorie_add), C.pareggi = (C.pareggi + casa_pareggi_add), C.sconfitte = (C.sconfitte + casa_sconfitte_add)
    WHERE C.insieme_squadre = insieme
    AND C.giornata IN (SELECT PT.giornata FROM partite_torneo PT WHERE PT.insieme = insieme AND PT.numero_giornata >= numero_giornata)
    AND C.squadra= squadra_casa;
    
    UPDATE Classifica C SET C.vittorie = C.vittorie + ospite_vittorie_add, C.pareggi = C.pareggi + ospite_pareggi_add, C.sconfitte = C.sconfitte + ospite_sconfitte_add 
    WHERE C.insieme_squadre = insieme
    AND C.giornata IN (SELECT PT.giornata FROM partite_torneo PT WHERE PT.insieme = insieme AND PT.numero_giornata >= numero_giornata)
    AND C.squadra= squadra_ospite;
END $$

CREATE TRIGGER TR_DEL_Partita_giocata BEFORE DELETE ON Partita_giocata
FOR EACH ROW
BEGIN
	DECLARE insieme				VARCHAR(7);
    DECLARE giornata			VARCHAR(7);
    DECLARE squadra_casa		VARCHAR(8);
    DECLARE squadra_ospite		VARCHAR(8);
    DECLARE errmsg				VARCHAR(127);
		
    -- Aggiornamento classifica
    SELECT insieme,giornata INTO insieme,giornata FROM partite_torneo WHERE partita = OLD.partita;
    SELECT squadra_casa, squadra_ospite INTO squadra_casa, squadra_ospite FROM Partita WHERE codice = OLD.partita;
    -- Eliminazione impedita se la partita non corrisponde all'ultima giornata in classifica
    IF giornata NOT IN (SELECT C.giornata FROM Classifica C WHERE C.insieme = insieme AND (C.squadra = squadra_casa OR C.squadra = squadra_ospite))
    THEN 
		SET errmsg = CONCAT("Eliminazione del risultato della partita ", OLD.partita, " non permessa. Eliminazione permessa solo per le ultime partite giocate.");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errmsg, MYSQL_ERRNO='5011';
    END IF;
    
    -- Eliminazione eseguita se si tratta dell'ultima partita
    DELETE FROM Classifica C WHERE 
    C.insieme = insieme AND 
    C.giornata = giornata AND
    C.squadra IN (squadra_casa, squadra_ospite);
    
END $$

CREATE TRIGGER TR_INS_Statistiche BEFORE INSERT ON Statistiche
FOR EACH ROW
BEGIN 
	DECLARE errmsg 						VARCHAR(127);
    DECLARE squadra_casa				VARCHAR(8);
    DECLARE somma_gol 					TINYINT UNSIGNED;
    DECLARE gol_squadra_giocatore	 	TINYINT UNSIGNED;
    DECLARE warnmsg						VARCHAR(127);
    DECLARE espulsioni_aggiunte			INT UNSIGNED;
    DECLARE giornata_inizio_espulsione	INT UNSIGNED;
    DECLARE ultima_giornata				INT UNSIGNED;
    
    -- Controllo ammonizioni appartenenti a {0,1,2}
    IF NEW.ammonizioni NOT IN (0,1,2)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Numero ammonizioni fuori dal dominio {0, 1, 2}.", MYSQL_ERRNO=5001;
    END IF;
    
    -- Controllo espulsioni pari ad almeno 1 se ammonizioni pari a 2
    IF NEW.ammonizioni = 2 AND NEW.espulsione_giornate < 1
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Giornate espulsione insufficienti dato ammonizioni pari a 2.", MYSQL_ERRNO='5010';
    END IF;
    
    -- Controllo giocatore possa partecipare a partita
    IF NEW.giocatore NOT IN 
		(SELECT giocatore FROM Rosa WHERE insieme_squadre = 
			(SELECT DISTINCT insieme FROM partite_torneo WHERE partita = NEW.partita_giocata))
	THEN
		SET errmsg = CONCAT("Giocatore ", NEW.giocatore, " non partecipante alla partita ", NEW.partita_giocata);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =errmsg, MYSQL_ERRNO = '5006';
	END IF;
        
    -- Inserimento espulsioni
    -- Nel caso in cui le giornate di espulsione siano maggiori di zero allora,
    -- viene eseguito un ciclo che aggiunge ad Espulsione istanze coerenti fintantoché 
    -- o sono state inserite tutte le giornate di espulsione oppure si è giurni all'ultima 
    -- giornata della fase per l'insieme.
    IF NEW.espulsione_giornate <> 0
    THEN
		SET espulsioni_aggiunte = 0;
        
        SELECT numero_giornata INTO giornata_inizio_espulsione FROM partite_torneo WHERE partita = NEW.partita_giocata;
        SELECT MAX(numero_giornata) INTO ultima_giornata FROM partite_torneo WHERE insieme IN
			((SELECT DISTINCT PT2.insieme FROM partite_torneo PT2 WHERE PT2.partita = NEW.partita_giocata));
		insert_espulsioni: WHILE (espulsioni_aggiunte < NEW.espulsione_giornate AND giornata_inizio_espulsione + espulsioni_aggiunte < ultima_giornata)		
        DO
			SET espulsioni_aggiunte = espulsioni_aggiunte +1;
			INSERT INTO Espulsione (giornata, giocatore) 
            VALUES ((SELECT DISTINCT giornata FROM partite_torneo WHERE numero_giornata = giornata_inizio_espulsione + espulsioni_aggiunte 
				AND insieme = (SELECT DISTINCT insieme FROM partite_torneo WHERE partita = NEW.partita_giocata)),
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
    
    -- Controllo giocatore possa partecipare a partita
    IF NEW.giocatore NOT IN 
		(SELECT giocatore FROM Rosa WHERE insieme_squadre = 
			(SELECT DISTINCT insieme FROM partite_torneo WHERE partita = NEW.partita_giocata))
	THEN
		SET errmsg = CONCAT("Giocatore ", NEW.giocatore, " non partecipante alla partita ", NEW.partita_giocata);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =errmsg, MYSQL_ERRNO = '5006';
	END IF;
END$$

CREATE TRIGGER TR_INS_Espulsione BEFORE INSERT ON Espulsione
FOR EACH ROW
BEGIN
	DECLARE errmsg VARCHAR(127);
	-- Controllo che il giocatore partecipi all'insieme
    IF NEW.giocatore NOT IN 
    (SELECT giocatore FROM Rosa WHERE insieme_squadre = 
		(SELECT G.insieme_squadre FROM Giornata G WHERE G.codice = NEW.giornata))
    THEN
		SET errmsg = CONCAT("Giocatore ", NEW.giocatore, " non partecipante all'insieme di squadre ", (SELECT G.insieme_squadre FROM Giornata G WHERE G.codice = NEW.giornata), ".");
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =errmsg, MYSQL_ERRNO = '5006';
    END IF;
END $$

CREATE TRIGGER TR_UPD_Espulsione BEFORE UPDATE ON Espulsione
FOR EACH ROW
BEGIN
	DECLARE errmsg VARCHAR(127);
	-- Controllo che il giocatore partecipi all'insieme
    IF NEW.giocatore NOT IN 
    (SELECT giocatore FROM Rosa WHERE insieme_squadre = 
		(SELECT G.insieme_squadre FROM Giornata G WHERE G.codice = NEW.giornata))
    THEN
		SET errmsg = CONCAT("Giocatore ", NEW.giocatore, " non partecipante all'insieme di squadre ", (SELECT G.insieme_squadre FROM Giornata G WHERE G.codice = NEW.giornata), ".");
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =errmsg, MYSQL_ERRNO = '5006';
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
(codice, nome, modalita, scontri, torneo, indice);

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
(insieme_squadre, squadra, giocatore, numero_maglia);

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
(codice, giornata, giorno, ora, squadra_casa, squadra_ospite, arbitro, campo);

LOAD DATA LOCAL INFILE './Popolamento/Partita_giocata.csv'
INTO TABLE Partita_giocata
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(partita, gol_casa, gol_ospite); 

LOAD DATA LOCAL INFILE './Popolamento/Statistiche.csv'
INTO TABLE Statistiche
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 2 LINES
(partita_giocata, giocatore, gol, assist, ammonizioni, espulsione_giornate); 

/*
 * SEZIONE PROCEDURE E FUNZIONI
 */
 
/*
 * La procedura successiva esegue il ricalcolo della classifica.
 * Dato che Classifca definisce all'interno del database delle ridondanze
 * allora occorrono dei meccanismi perchè questa sia sempre aggiornata.
 * Questa procedura si inserisce in questo contesto, eseguendo il ricalcolo
 * della classifica nel momento in cui viene chiamata, come ad esempio 
 * all'inserimento di un'istanza di Partita_giocata
 */
DELIMITER $$
CREATE PROCEDURE calcolo_classifica()
BEGIN
END $$


DELIMITER ; 
/*
 * La procedura successiva occorre per l'inserimento di Statistiche.
 * Alcuni inserimenti di questa tabella vengono inseriti tramite questa
 * per mostrarne il funzionamento.
 */

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
# SELECT * FROM Partita_giocata;

SELECT * FROM Classifica WHERE insieme_squadre = 'I-1';


UPDATE Partita_giocata SET gol_casa = 6, gol_ospite= 0
WHERE partita = 'P-2';

SELECT PT.insieme, PT.numero_giornata FROM partite_torneo PT WHERE PT.partita = 'P-2';
    SELECT squadra_casa, squadra_ospite FROM Partita WHERE codice = 'P-2';
    
    SELECT * FROM Classifica C
    WHERE C.insieme_squadre = 'I-1'
    AND C.giornata IN (SELECT PT.giornata FROM partite_torneo PT WHERE PT.insieme = 'I-1' AND PT.numero_giornata >= 1)
    AND C.squadra= 'S-4';
