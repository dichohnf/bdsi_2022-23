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
    nome		CHAR(1) DEFAULT 0 NOT NULL,	/* PROTOCOLLO: Lettera capitale dell'alfabeto
											* o 0 per le Fasi con un solo Insieme di squadre */
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
	nome			VARCHAR(100) NOT NULL,			-- La dimensione elevata permette l'inserimento di secondi nomi
    cognome			VARCHAR(100) NOT NULL,			-- La dimensione elevata permette l'inserimento di vari cognomi
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
    partita_giocata		VARCHAR(9) NOT NULL,
	giocatore			SMALLINT UNSIGNED NOT NULL,
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
(torneo, nome, edizione, genere, tipologia) AS
(SELECT codice, nome, edizione, genere, tipologia FROM Torneo 
WHERE codice IN
	(SELECT torneo FROM Fase 
    WHERE codice IN 
		(SELECT fase FROM Insieme_squadre 
        WHERE codice IN 
			(SELECT insieme_squadre FROM Giornata 						-- Giornate con almeno una partita e che ha tutte le partite già giocate.
            WHERE codice IN												
				(SELECT giornata FROM Partita)																	
			AND codice NOT IN
				(SELECT giornata FROM Partita 
                WHERE codice NOT IN 
					(SELECT partita FROM Partita_giocata))))));			-- Partite non ancora giocate, ovvero partite che non hanno un'istanza corrispondente in Partita_giocata
                
/*
 * La successiva vista rappresenta l'insieme dei codici delle squadre partecipanti
 * associati ai tornei a cui partecipano e in quali fasi dei suddetti tornei.
 * Questa vista occorre per la verivica del vincolo di partecipazione singola
 * di una squadra ad una fase
 */
CREATE VIEW squadra_iscrizioni
(torneo, fase, insieme, squadra) AS
SELECT torneo, fase, insieme, squadra FROM 
	(SELECT F.torneo, F.codice AS fase, I.codice AS insieme
    FROM Fase F, Insieme_squadre I 
    WHERE F.codice = I.fase) AS TFI 
	NATURAL JOIN 
	(SELECT insieme_squadre AS insieme, squadra
    FROM Raggruppamento) AS R;

/*
 * La seguente vista mostra l'elenco delle partite per ogni torneo, 
 * comprese le squadre che giocano la suddetta partita.
 */
 CREATE VIEW partite_torneo 
 (torneo, fase, insieme, giornata, numero_giornata, partita, squadra_casa, squadra_ospite) AS
 SELECT torneo, fase, insieme, giornata, numero_giornata, partita, squadra_casa, squadra_ospite FROM 
	(SELECT F.torneo, F.codice AS fase, I.codice AS insieme FROM Fase F, Insieme_squadre I
    WHERE F.codice = I.fase) AS TFI 
	NATURAL JOIN
	(SELECT G.insieme_squadre AS insieme, G.codice AS giornata, G.numero AS numero_giornata, P.codice AS partita, P.squadra_casa, P.squadra_ospite
    FROM Giornata G, Partita P
    WHERE P.giornata = G.codice) AS GP;

/*
 * La successiva vista mostra solo le partite giocate unite alle informazioni
 * sul torneo, insieme di squadre, squadre ecc.
 */
CREATE VIEW partite_giocate_torneo
(torneo, fase, insieme, giornata, numero_giornata, partita, squadra_casa, squadra_ospite, gol_casa, gol_ospite) AS
SELECT torneo, fase, insieme, giornata, numero_giornata, PT.partita, squadra_casa, squadra_ospite, gol_casa, gol_ospite 
FROM partite_torneo PT, Partita_giocata PG 
WHERE PT.partita = PG.partita;

/*
 * La successiva procedura recupera i valori di vittorie, pareggi e sconfitte
 * in Clasifica della giornata precedente a quella indicata come parametro
 * per la squadra nell'insieme specificata e li inserisce nei parametri di output.
 * Questa funzione occorre nell'inserimeto, modifica e rimozione di partite giocate 
 * per l'aggioramento della classifica.
 */
DELIMITER $$
CREATE PROCEDURE risultati_giornata_precedente (IN insieme VARCHAR(7), IN giornata VARCHAR(7), IN numero_giornata TINYINT UNSIGNED, IN squadra VARCHAR(8), 
OUT vittorie TINYINT UNSIGNED, OUT pareggi TINYINT UNSIGNED, OUT sconfitte TINYINT UNSIGNED)
BEGIN
	IF numero_giornata = 1
    THEN SELECT 0,0,0 INTO vittorie,pareggi,sconfitte;
    ELSE
		SELECT C.vittorie, C.pareggi, C.sconfitte 
        INTO vittorie, pareggi, sconfitte
        FROM Classifica C 
        WHERE C.insieme_squadre = insieme
        AND C.giornata = 
			(SELECT G.codice FROM Giornata G 
			WHERE G.insieme_squadre = insieme 
            AND G.numero = numero_giornata-1)
		AND C.squadra = squadra;
	END IF;
END $$

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
		SELECT genere INTO genere_squadra 
        FROM Squadra WHERE codice = 
			(SELECT squadra FROM squadra_iscrizioni 
			WHERE torneo = OLD.codice LIMIT 1);
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
		SELECT genere FROM Giocatore
        WHERE codice IN 
			(SELECT giocatore FROM Rosa 
            WHERE squadra=OLD.codice);
	DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;
    
	-- Controllo formato codice
    IF NEW.codice NOT LIKE 'S-_%' OR NEW.codice IS NULL 
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Formato codice non accettabile. Il codice inserito come nuovo codice non rispetta il formato per il campo.", MYSQL_ERRNO='5009';
	END IF;
        
	-- Controllo genere concordante tra Squadra e Torneo
    SELECT genere INTO genere_torneo
    FROM Torneo WHERE codice = 
		(SELECT torneo FROM squadra_iscrizioni 
		WHERE squadra = OLD.codice LIMIT 1);
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
    
    -- Controllo genere concordante tra Squadra e Torneo
	SELECT genere INTO genere_squadra 
    FROM Squadra WHERE codice = NEW.squadra;
    SELECT genere INTO genere_torneo
    FROM Torneo WHERE codice = 
		(SELECT DISTINCT torneo FROM squadra_iscrizioni 
        WHERE insieme = NEW.insieme_squadre);
    IF genere_squadra <> genere_torneo
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
    -- Controllo che la squadra non stia gia partecipando alla fase
    IF (NEW.squadra IN 
		(SELECT isc.squadra FROM squadra_iscrizioni AS isc WHERE isc.fase IN 
			(SELECT I.fase FROM Insieme_squadre I WHERE I.codice = NEW.insieme_squadre)))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Squadra già partecipante alla fase.', MYSQL_ERRNO='5004';
    END IF;
END $$

CREATE TRIGGER TR_UPD_Raggruppamento BEFORE UPDATE ON Raggruppamento
FOR EACH ROW
BEGIN
	DECLARE genere_squadra 		ENUM('M','F','N');
    DECLARE genere_torneo 		ENUM('M','F','N');
    DECLARE errmsg				VARCHAR(127);
	DECLARE giocatore_check		VARCHAR(8);
    DECLARE giocatore_cursor	CURSOR FOR 
		SELECT giocatore FROM Rosa 
        WHERE insieme_squadre = NEW.insieme_squadre 
        AND squadra = NEW.squadra;
	DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;
    
    -- Controllo genere concordante tra Squadra e Torneo
	SELECT genere INTO genere_squadra 
    FROM Squadra WHERE codice = NEW.squadra;
    SELECT genere INTO genere_torneo 
    FROM Torneo WHERE codice = 
		(SELECT torneo FROM squadra_iscrizioni
        WHERE insieme = NEW.insieme_squadre);
    IF genere_squadra <> genere_torneo
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
	-- Controllo che la squadra non stia gia partecipando alla fase
    IF (NEW.squadra IN 
		(SELECT isc.squadra FROM squadra_iscrizioni AS isc 
        WHERE isc.fase IN 
			(SELECT I.fase FROM Insieme_squadre I 
            WHERE I.codice = NEW.insieme_squadre)))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Squadra già partecipante alla fase.', MYSQL_ERRNO='5004';
    END IF;
    
    -- Controllo che le squadre abbiano tutti giocatori differenti
    OPEN giocatore_cursor;
    check_giocatore_gia_iscritto: LOOP -- leave sottointesa: uscita con la exit dell'handler al termine dei fetch del cursore
		FETCH giocatore_cursor INTO giocatore_check;
        IF 
			(SELECT COUNT(giocatore) FROM 
			(SELECT R.giocatore FROM Rosa R 
			WHERE R.giocatore = giocatore_check 
            AND R.insieme_squadre = NEW.insieme_squadre) 
			giocatore_times)  <> 1
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
 * tessere e lasciarle generare al trigger, a meno che non si desideri mantenere
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
	SELECT Squadra.genere INTO genere_squadra 
    FROM Squadra WHERE Squadra.codice = NEW.squadra;
    SELECT Giocatore.genere INTO genere_giocatore 
    FROM Giocatore WHERE Giocatore.tessera = NEW.Giocatore;
    IF genere_squadra <> 'N' AND genere_squadra <> genere_giocatore		-- Squadre miste accettano giocatori di ogni genere
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
    -- Controllo che le squadre dell'insieme abbiano tutti giocatori differenti
	IF 
		(SELECT ALL COUNT(giocatore) FROM Rosa 
		WHERE insieme_squadre = NEW.insieme_squadre 
        AND giocatore = NEW.giocatore) > 1
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
	SELECT Squadra.genere INTO genere_squadra
    FROM Squadra WHERE Squadra.codice = NEW.squadra;
    SELECT Giocatore.genere INTO genere_giocatore
    FROM Giocatore WHERE Giocatore.tessera = NEW.Giocatore;
    IF genere_squadra <> 'N' AND genere_squadra <> genere_giocatore		-- Squadre miste accettano giocatori di ogni genere
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Genere discorde. Il genere della squadra e del torneo devono essere concordi.', MYSQL_ERRNO='5000';
	END IF;
    
	-- Controllo che le squadre abbiano tutti giocatori differenti
    IF 
		(SELECT ALL COUNT(giocatore) FROM Rosa
		WHERE insieme_squadre = NEW.insieme_squadre 
        AND giocatore = NEW.giocatore) <> 0
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

CREATE TRIGGER TR_UPD_Partita_giocata AFTER UPDATE ON Partita_giocata
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
    
    -- Aggiornamento classifica
    SELECT PT.insieme, PT.numero_giornata INTO insieme, numero_giornata
    FROM partite_torneo PT WHERE PT.partita = NEW.partita;
    SELECT P.squadra_casa, P.squadra_ospite INTO squadra_casa, squadra_ospite
    FROM Partita P WHERE codice = NEW.partita;
    SELECT 0,0,0,0,0,0 INTO casa_vittorie_add, casa_pareggi_add, casa_sconfitte_add, ospite_vittorie_add, ospite_pareggi_add, ospite_sconfitte_add;

    IF OLD.gol_casa < OLD.gol_ospite 
	THEN SET casa_sconfitte_add = -1;
         SET ospite_vittorie_add = -1;
	ELSEIF OLD.gol_casa = OLD.gol_ospite
	THEN SET casa_pareggi_add = -1;
         SET ospite_pareggi_add = -1;
	ELSE SET casa_vittorie_add = -1;
         SET ospite_sconfitte_add = -1;
	END IF;

	IF NEW.gol_casa < NEW.gol_ospite 
	THEN SET casa_sconfitte_add = casa_sconfitte_add +1;
         SET ospite_vittorie_add = ospite_vittorie_add +1;
	ELSEIF NEW.gol_casa = NEW.gol_ospite
	THEN SET casa_pareggi_add = casa_pareggi_add +1;
         SET ospite_pareggi_add = ospite_pareggi_add +1;
	ELSE SET casa_vittorie_add = casa_vittorie_add +1;
         SET ospite_sconfitte_add = ospite_sconfitte_add +1;
	END IF;

	UPDATE Classifica C SET 
		C.vittorie = (C.vittorie + casa_vittorie_add), 
        C.pareggi = (C.pareggi + casa_pareggi_add), 
        C.sconfitte = (C.sconfitte + casa_sconfitte_add)
    WHERE C.insieme_squadre = insieme
    AND C.giornata IN 
		(SELECT PT.giornata FROM partite_torneo PT 
        WHERE PT.insieme = insieme 
        AND PT.numero_giornata >= numero_giornata)
    AND C.squadra= squadra_casa;

    UPDATE Classifica C SET 
		C.vittorie = C.vittorie + ospite_vittorie_add, 
		C.pareggi = C.pareggi + ospite_pareggi_add, 
        C.sconfitte = C.sconfitte + ospite_sconfitte_add 
    WHERE C.insieme_squadre = insieme
    AND C.giornata IN 
		(SELECT PT.giornata FROM partite_torneo PT 
		WHERE PT.insieme = insieme 
        AND PT.numero_giornata >= numero_giornata)
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
    SELECT insieme,giornata INTO insieme,giornata 
    FROM partite_torneo WHERE partita = OLD.partita;
    SELECT squadra_casa, squadra_ospite 
    INTO squadra_casa, squadra_ospite 
    FROM Partita WHERE codice = OLD.partita;
    -- Eliminazione impedita se la partita non corrisponde all'ultima giornata in classifica
    IF giornata NOT IN 
			(SELECT C.giornata FROM Classifica C 
            WHERE C.insieme = insieme 
            AND (C.squadra = squadra_casa OR C.squadra = squadra_ospite))
    THEN 
		SET errmsg = CONCAT("Eliminazione del risultato della partita ", OLD.partita, " non permessa. Eliminazione permessa solo per le ultime partite giocate.");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errmsg, MYSQL_ERRNO='5011';
    END IF;
    
    -- Eliminazione eseguita se si tratta dell'ultima partita
    DELETE FROM Classifica C 
    WHERE C.insieme = insieme 
    AND C.giornata = giornata 
    AND C.squadra IN (squadra_casa, squadra_ospite);
END $$

CREATE TRIGGER TR_INS_Statistiche BEFORE INSERT ON Statistiche
FOR EACH ROW
BEGIN 
	DECLARE insieme_partita				VARCHAR(7);
	DECLARE errmsg 						VARCHAR(127);
    DECLARE squadra_giocatore			VARCHAR(8);
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
    SELECT insieme INTO insieme_partita 
    FROM partite_torneo 
    WHERE partita = NEW.partita_giocata;
    SELECT squadra INTO squadra_giocatore FROM Rosa 
    WHERE insieme_squadre = insieme_partita 
    AND giocatore = NEW.giocatore;
    
    IF NEW.giocatore NOT IN 
		(SELECT giocatore FROM Rosa 
        WHERE insieme_squadre =
			(SELECT DISTINCT insieme FROM partite_torneo 
			WHERE partita = NEW.partita_giocata)
		AND squadra = squadra_giocatore)
	THEN
		SET errmsg = CONCAT("Giocatore ", NEW.giocatore, " non partecipante alla partita ", NEW.partita_giocata);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =errmsg, MYSQL_ERRNO = '5006';
	END IF;
        
    -- Inserimento espulsioni
    -- Nel caso in cui le giornate di espulsione siano maggiori di zero allora
    -- viene eseguito un ciclo che aggiunge ad Espulsione istanze coerenti fintantoché 
    -- o sono state inserite tutte le giornate di espulsione oppure si è giurti all'ultima 
    -- giornata della fase per l'insieme.
    IF NEW.espulsione_giornate <> 0
    THEN
		SET espulsioni_aggiunte = 0;
        SELECT numero_giornata INTO giornata_inizio_espulsione 
        FROM partite_torneo 
        WHERE partita = NEW.partita_giocata;
        SELECT MAX(numero_giornata) INTO ultima_giornata 
        FROM partite_torneo 
        WHERE insieme IN
			(SELECT DISTINCT PT2.insieme FROM partite_torneo PT2 
            WHERE PT2.partita = NEW.partita_giocata);
            
		insert_espulsioni: 
        WHILE 
			(espulsioni_aggiunte < NEW.espulsione_giornate 
			AND giornata_inizio_espulsione + espulsioni_aggiunte < ultima_giornata)		
        DO
			SET espulsioni_aggiunte = espulsioni_aggiunte +1;
			INSERT INTO Espulsione (giornata, giocatore) 
            VALUES 
				((SELECT DISTINCT giornata FROM partite_torneo 
				WHERE numero_giornata = giornata_inizio_espulsione + espulsioni_aggiunte 
				AND insieme = 
					(SELECT DISTINCT insieme FROM partite_torneo 
					WHERE partita = NEW.partita_giocata)),
                NEW.giocatore);
        END WHILE;
	END IF;		
END $$

CREATE TRIGGER TR_UPD_Statistiche BEFORE UPDATE ON Statistiche
FOR EACH ROW
BEGIN
	DECLARE squadra_casa			VARCHAR(8);
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
		(SELECT giocatore FROM Rosa 
        WHERE insieme_squadre = 
			(SELECT DISTINCT insieme FROM partite_torneo 
            WHERE partita = NEW.partita_giocata))
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
		(SELECT giocatore FROM Rosa 
        WHERE insieme_squadre = 
			(SELECT G.insieme_squadre FROM Giornata G
            WHERE G.codice = NEW.giornata))
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
		(SELECT giocatore FROM Rosa
        WHERE insieme_squadre = 
			(SELECT G.insieme_squadre FROM Giornata G
            WHERE G.codice = NEW.giornata))
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
            
-- Inserimento tramite file non standard (tabella Fase)
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
 * SEZIONE PROCEDURE, FUNZIONI E VISTE PER GLI UTENTI
 */

/*
 * La procedura successiva occorre per l'inserimento di Statistiche.
 * Alcune istanze vengono inserite tramite la procedura per mostrarne il funzionamento.
 * La differenza principale con l'inserimento manuale è il controllo eseguito sul
 * totale delle statistiche inserite nella partita: se questo non combacia con il risultato
 * viene mostrato all'utente una segnalazione di inconsistenza attraverso uno warning.
 */
 DELIMITER $$ 
CREATE PROCEDURE inserimento_statistiche (IN new_partita VARCHAR(9), IN new_giocatore SMALLINT UNSIGNED,
IN new_gol TINYINT UNSIGNED, IN new_assist TINYINT UNSIGNED, IN new_ammonizioni TINYINT UNSIGNED, 
IN new_espulsione_giornate TINYINT UNSIGNED)
BEGIN
	DECLARE insieme_partita				VARCHAR(7);
    DECLARE giornata_partita			VARCHAR(7);
	DECLARE squadra_giocatore			VARCHAR(8);
	DECLARE somma_gol_squadra			TINYINT UNSIGNED;
    DECLARE punteggio_squadra_partita	TINYINT UNSIGNED;
    DECLARE warnmsg						VARCHAR(127);
    
	-- Inserimento in Statistiche
	INSERT INTO Statistiche (partita_giocata, giocatore, gol, assist, ammonizioni, espulsione_giornate)
    VALUES (new_partita, new_giocatore, new_gol, new_assist, new_ammonizioni, new_espulsione_giornate);
    
    -- Controllo di consistenza database
    SELECT insieme, giornata INTO insieme_partita, giornata_partita 
    FROM partite_torneo WHERE partita = new_partita;
    SELECT squadra INTO squadra_giocatore FROM Rosa
    WHERE insieme_squadre = insieme_partita
    AND giocatore = new_giocatore;
    SELECT SUM(gol) INTO somma_gol_squadra FROM Statistiche
    WHERE partita_giocata = new_partita
    AND giocatore IN 
		(SELECT giocatore FROM Rosa 
        WHERE insieme_squadre = insieme_partita
        AND squadra = squadra_giocatore);
    SELECT IF(squadra_giocatore = (SELECT squadra_casa FROM Partita WHERE codice = new_partita), gol_casa, gol_ospite) 
    INTO punteggio_squadra_partita FROM Partita_giocata
    WHERE partita = new_partita;
    
    -- Segnalazione eventuale inconsistenza
	IF somma_gol_squadra <> punteggio_squadra_partita
    THEN
		SET warnmsg = CONCAT("Il puteggio della partita ", new_partita, " e la somma dei gol fatti dalla squadra ", squadra_giocatore, " non corrispondono per ", punteggio_squadra_partita - somma_gol_squadra," gol.");
        SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT=warnmsg, MYSQL_ERRNO='5012';
	END IF;
END $$

/*
 * La successiva vista mostra la classifica nel formato 
 * (insieme_squadre, squadra, giornata, numero partite giocate, punti, vittorie, pareggi, sconfitte, gol fatti, gol subiti, differenza reti)
 * dove i punti sono calcolati attraverso lo schema: 1 vittoria +3, 1 pareggio +1.
 * La vista è pensata per gli insiemi di squadre con modalità a gironi. Nel caso di 
 * insiemi ad eliminazione la funzione produce un risultato che non è significativo.
 * Per ottenere la classifica di un girone aggiornata all'ultima partita giocata può essere utilizzata 
 * la seguente vista, ma specifica per lo scopo è la vista classifca_punti_aggiornata mostrata nel seguito.
 */
 DELIMITER ;
CREATE VIEW	classifica_punti_giornata
(insieme_squadre, squadra, giornata, numero_partite_giocate, punti, vittorie, pareggi, sconfitte) AS
SELECT insieme_squadre, squadra, giornata, vittorie+pareggi+sconfitte AS numero_partite_giocate, SUM(vittorie *3 + pareggi) AS punti, vittorie, pareggi, sconfitte
FROM Classifica
GROUP BY insieme_squadre, squadra, giornata;

CREATE VIEW classifica_punti_aggiornata 
(insieme_squadre, squadra, giornata, numero_partite_giocate, punti, vittorie, pareggi, sconfitte) AS
SELECT CPG.insieme_squadre, squadra, giornata, numero_partite_giocate, punti, vittorie, pareggi, sconfitte
FROM classifica_punti_giornata CPG
WHERE numero_partite_giocate = 
	(SELECT MAX(PGT.numero_giornata)
    FROM partite_giocate_torneo PGT 
    WHERE PGT.insieme = CPG.insieme_squadre);

/*
 * La successiva vista mostra le prossime partite da giocare per ogni inseme di squadre
 * dove risultano definite delle istanze in Partita. Qualora siano definite giornate
 * per una fase ma in queste non sono ancora state predisposte partite allora
 * queste non saranno prese in considerazione.
 */
CREATE VIEW prossime_partite
(insieme_squadre, giornata, partita, giorno, ora, campo, squadra_casa, squadra_ospite) AS
SELECT insieme, giornata, partita, giorno, ora, campo, squadra_casa, squadra_ospite
FROM 
	(SELECT insieme, giornata, partita FROM partite_torneo 
    WHERE partita NOT IN 
		(SELECT partita FROM Partita_giocata)
    AND numero_giornata = 
		(SELECT MIN(numero) FROM Giornata 
        WHERE codice IN (SELECT giornata FROM Partita)
        AND codice NOT IN (SELECT giornata FROM partite_giocate_torneo))) PT
    NATURAL JOIN
    (SELECT codice AS partita, giorno, ora, campo, squadra_casa, squadra_ospite 
    FROM Partita) P;

/*
 * La successiva vista mostra, gli squalificati nella prossima partita.
 * Il risparmio di operazioni è immediatamente visibile data la presenza
 * della tabella Espulsione.
 */
CREATE VIEW squalificati_prossima_partita
(torneo, fase, insieme_squadre, giornata, tessera, nome, cognome, data_nascita) AS
SELECT torneo, fase, insieme, giornata, tessera, nome, cognome, data_nascita
FROM
	(SELECT PT.torneo, PT.Fase, PT.insieme, E.giornata, E.giocatore AS tessera 
    FROM partite_torneo PT, Espulsione E 
    WHERE E.giornata IN 
		(SELECT PP.giornata FROM prossime_partite PP 
		WHERE PP.insieme_squadre = PT.insieme)
	AND PT.giornata = E.giornata) PTE
	NATURAL JOIN
	(SELECT tessera, nome, cognome, data AS data_nascita 
    FROM Giocatore) G; 
    
/*
 * La prossima vista occorre per elencare la somma delle statistiche
 * di ogni giocatore divise per insieme di squadre.
 * Attraverso l'utilizzo di questa vista risulta immediata la generazione
 * di viste, procedure o funzioni che restituiscano giocatori che hanno segnato
 * più gol in un dato insieme, quelli che hanno eseguito più assist oppure
 * quelli che hanno preso piu cartellini, tutte operazioni frequentemente
 * richieste per contesti simili a quello proposto.
 */
CREATE VIEW somma_statistiche_giocatore
(torneo, fase, insieme_squadre, squadra, tessera, nome, cognome, data, genere, gol, assist, ammonizioni, espulsione_giornate) AS
SELECT PT.torneo, PT.fase, PT.insieme, R.squadra, R.giocatore, G.nome, G.cognome, G.data, G.genere, SUM(S.gol), SUM(S.assist), SUM(S.ammonizioni), SUM(S.espulsione_giornate)
FROM  partite_torneo PT, Rosa R, Statistiche S, Giocatore G
WHERE PT.insieme = R.insieme_squadre
AND	  R.giocatore = S.giocatore
AND   R.giocatore = G.tessera
AND   S.partita_giocata = PT.partita
GROUP BY torneo, fase, insieme_squadre,squadra, tessera, nome, cognome, data, genere;

/*
 * La successiva procedura inserisce in Raggruppamento delle istanze
 * affichè sia generato un nuovo insieme di squadre per la fase successiva
 * a quella specificata, comprendente le squadre tra le posizioni in classifica
 * indicate come parametri degli insieme di squadre della fase.
 * La procedura è progettata per creare fasi ad eliminazione a partire da
 * gironi ma produce un risultato utilizzabile anche se si vuole inserire
 * le squadre in una fase a giorni.
 * Il nome occorre per la creazione dell'insieme nella fase
 * specificata in fase_inserimenti
 * Le posizioni specificate sono ambedue comprese; in caso si desideri
 * selezionare un'unica squadra è sufficiente ripeterla due volte.
 * posizione_prima si riferisce alla posizione più vicina alla prima
 * posizione in classifica, ovvero un intero minore o uguale a 
 * posizione_ultima.
 * La procedura utilizza la classifca aggiornata per definire
 * l'insieme, ovvero considera la fase specificata conclusa.
 */
DELIMITER $$
CREATE PROCEDURE ragguppamento_fase_successiva (IN fase_derivazione VARCHAR(6), 
IN posizione_prima TINYINT, IN posizione_ultima TINYINT, IN fase_inserimenti VARCHAR(6), IN nome_insieme CHAR(1))
LANGUAGE SQL
MODIFIES SQL DATA
NOT DETERMINISTIC
BEGIN
	DECLARE limit_				TINYINT;
	DECLARE offset_ 			TINYINT;
	DECLARE insieme_generato	VARCHAR(7);
	DECLARE insieme_fetched		VARCHAR(7);
	DECLARE squadra_da_inserire	VARCHAR(8);
    DECLARE not_found			BOOLEAN;
	DECLARE insieme_cursor 		CURSOR FOR
		SELECT I.codice FROM Insieme_squadre I 
        WHERE I.fase = fase_derivazione;
	DECLARE squadre_cursor 		CURSOR FOR	
		SELECT squadra FROM classifica_punti_aggiornata 
			WHERE insieme_squadre = insieme_fetched
			ORDER BY punti DESC 
			LIMIT limit_ OFFSET offset_;
	DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN
		SET not_found = TRUE;
    END;
	
	-- Generazione insieme
	INSERT INTO Insieme_squadre (fase, nome)
	VALUES (fase_inserimenti, nome_insieme);
	SELECT codice INTO insieme_generato 
    FROM Insieme_squadre 
	WHERE fase = fase_inserimenti
    AND nome = nome_insieme;
	
    
	SET limit_ = posizione_ultima - posizione_prima +1;
	SET offset_ = posizione_prima -1;
	OPEN insieme_cursor;
	insieme_loop: LOOP
		SET not_found = FALSE;
		FETCH insieme_cursor INTO insieme_fetched;
        IF not_found
        THEN LEAVE insieme_loop;
        END IF;
		OPEN squadre_cursor;
        squadre_loop: LOOP
			FETCH squadre_cursor INTO squadra_da_inserire;
            IF not_found
			THEN LEAVE squadre_loop;
			END IF;
            SELECT squadra_da_inserire;
			INSERT INTO Raggruppamento (insieme_squadre, squadra)
			VALUES (insieme_generato, squadra_da_inserire);
		END LOOP squadre_loop; 
        CLOSE squadre_cursor;
	END LOOP insieme_loop;
END $$

/*
 * La successiva procedura esegue l'inserimento in Giornata di un numero
 * di istanze necessarie affinché l'insieme di squadre specificato possa essere 
 * saturo, ovvero il numero di giornate minime necessarie perchè un insieme possa 
 * non aver bisogno di altre giornate. Occorre per evitare al gestore del database 
 * numerevoli inserimenti manuali, dato che il numero di giornate è predefinito dal 
 * numero di squadre nell'insieme di squadre associato. Occorre quindi aver 
 * precedentemente completato il ragruppamento dell'insieme delle squadre in un girone.
 */
 CREATE PROCEDURE riempimento_giornate (IN insieme_ VARCHAR(7))
 BEGIN
	DECLARE num_squadre				SMALLINT UNSIGNED;
    DECLARE modalita_fase			ENUM('Girone', 'Eliminazione');
    DECLARE num_scontri				TINYINT UNSIGNED;
	DECLARE num_giornate_totale		TINYINT UNSIGNED;
    DECLARE num_giornate_aggiunte	TINYINT UNSIGNED;
    
    SELECT COUNT(squadra) INTO num_squadre 
    FROM Raggruppamento 
    WHERE insieme_squadre = insieme_;
    SELECT scontri, modalita INTO num_scontri, modalita_fase
    FROM Fase 
	WHERE codice = 
		(SELECT fase FROM Insieme_squadre
        WHERE codice = insieme_);
    
    -- I vincoli di giornate minime non sono specificati nella relazione, 
    -- vengono mostrati due valori tipici nei tornei calcistici per 
    -- mostrare la tipologia di procedura.
    IF modalita_fase = 'Girone'
    THEN SET num_giornate_totale = (num_squadre -1) * num_scontri;
    ELSE SET num_giornate_totale = FLOOR(LOG2(num_squadre)) * num_scontri;
    END IF;
    SET num_giornate_aggiunte = 0;
    
    WHILE num_giornate_aggiunte < num_giornate_totale
    DO
		SET num_giornate_aggiunte = num_giornate_aggiunte + 1;
        INSERT INTO Giornata (codice, insieme_squadre, numero)
        VALUES (NULL, insieme_, num_giornate_aggiunte);
	END WHILE;
 END $$

/*
 * La successiva funzione controlla, per una partita indicata
 * se il campo assegnato risulta essere il campo di casa
 * della squadra partecipante alla partita passata come parametro.
 * La funzione restituisce un valore booleano.
 */
CREATE FUNCTION is_campo_casa (partita_ VARCHAR(8), squadra_ VARCHAR(8))
RETURNS BOOLEAN
LANGUAGE SQL
NOT DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE errmsg VARCHAR(127);
	IF squadra_ NOT IN 
		((SELECT squadra_casa AS squadra FROM Partita 
        WHERE codice = partita_)
        UNION
        (SELECT squadra_ospite AS squadra FROM Partita
        WHERE codice = partita_))
    THEN
		SET errmsg = CONCAT("La squadra ", squadra_, " non partecipa alla partita ", partita_);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errmsg, MYSQL_ERRNO='5013';
    END IF;
    RETURN
		(SELECT campo FROM Squadra
        WHERE codice = squadra_)
        =
        (SELECT campo FROM Partita
        WHERE codice = partita_);
END $$

/*
 * SEZIONE DEDICATA AGLI ESEMPI DI FUNZIONAMENTO
 */
 
/*
 * La successiva sezione mostra, per tutte le procedure, funzioni e viste
 * mostarte nella precedente sezione un esempio di funzionamento.
 */

/*
 * Vengono eseguiti nel seguito 5 inserimenti attraverso la procedura
 * inserimenti_statistiche. I primi 2 inserimenti segnalano uno warning,
 * gli altri invece vengono eseguiti senza segnalazioni.
 */
DELIMITER ;
-- CALL inserimento_statistiche ('P-13', 44, 2, 1, 0, 0);
-- CALL inserimento_statistiche ('P-13', 46, 0, 1, 0, 0);
-- CALL inserimento_statistiche ('P-13', 48, 1, 0, 0, 0);
-- CALL inserimento_statistiche ('P-13', 0, 1, 0, 0, 0);
-- CALL inserimento_statistiche ('P-14', 37, 1, 0, 0, 0);

/*
 * Si mostra nel seguito un possibile utilizzo della vista classifica_punti_giornata
 * nella quale si mostra la classifica punti dell'insieme specificato
 * alla giornata specificata, senza operare altre selezioni;
 */
-- SELECT * FROM classifica_punti_giornata WHERE insieme_squadre = 'I-0' AND numero_partite_giocate = 2;
  
  /*
 * Si mostra nel seguito un possibile utilizzo della vista prossime_partite
 * nella quale si mostra il calendario delle partite della prossima 
 * giornata per un insieme di squadre specificato.
 * Come si può vedere le partite dell'insieme I-2 sono concluse,
 * quindi il risultato è una tabella vuota, mentre quelle di 
 * I-3 sono ancora in corso, per cui si mostrano le partite della 
 * successiva giornata da disputare.
 */
-- SELECT * FROM prossime_partite WHERE insieme_squadre = 'I-2';
-- SELECT * FROM prossime_partite WHERE insieme_squadre = 'I-3';

/*
 * Si mostra nel seguito un possibile utilizzo della vista squalificati_prossima_partita
 * nella quale si mostra l'elenco dei giocatori squalificati nella 
 * prossima giornata, specificato il Torneo.
 * In questo caso i tornei o sono terminati o devono iniziare,
 * quindi non risulteranno squalificati nella tabella in nessun torneo.
 */
-- SELECT * FROM squalificati_prossima_partita WHERE torneo = 'T-0';
  
/*
 * Si mostrano nel seguito alcuni possibili utilizzi della vista somma_statistiche_giocatore
 * nella quale si mostrano gli elenco dei 10 giocatori con maggior
 * numero di statistiche di un dato attributo,
 * ovvero la lista dei capocannonieri, la lista degli assistmen, ecc.
 * Questa vista non avrebbe avuto molto senso ampliarla 
 */
-- SELECT nome, cognome, data, gol FROM somma_statistiche_giocatore WHERE torneo ='T-0' ORDER BY gol DESC LIMIT 10;
-- SELECT nome, cognome, data, ammonizioni FROM somma_statistiche_giocatore WHERE torneo ='T-0' ORDER BY ammonizioni DESC LIMIT 10;

/*
 * Si esegue nel seguito la combinazione delle procedure ragguppamento_fase_successiva e 
 * riempimento_giornate per impostare una fase ad eliminazione diretta automaticamente.
 * Il gestore del database otterrà un database arricchito con uninsieme aggiuntivo 
 * che raggruppa le migliori squadre di una fase e per il quel sono gia state definite
 * le giornate minime di gioco. Sebbene non formalemnte corretto, utilizziamo 
 * la fase F-0 (terminata) per selezionare le squadre da inserire nel nuovo insieme.
 * In particolare si crea una fase ad eleiminazione con 2 scontri accoppiamento e con 
 * l'insieme da 4 squadre, per cui il numero di giornate create risultanti è 4.
 */
 
-- Creazione manuale delle nuova fase in cui inserire l'insieme
-- INSERT INTO Fase (torneo, nome, modalita, scontri, indice)
-- VALUES ('T-0', "Fase finale prova", 'Eliminazione', 2, 3);	-- Si crea una fase con indice 3 poichè la 2 esiste già
-- Si selezionano le migliori 2 squadre da ogni girone della fase F-0
-- CALL ragguppamento_fase_successiva('F-0', 1, 2, 'F-3', 'A');
-- SELECT codice INTO @insieme FROM Insieme_squadre WHERE fase = 'F-3' AND nome = 'A';
-- Si mostra che la procedura ha eseguito il proprio compito correttamente
-- SELECT * FROM Raggruppamento WHERE insieme_squadre = @insieme;
-- Si creano il minimo numero di giornate per il raggruppamento appena eseguito
-- CALL riempimento_giornate(@insieme);
-- Si mostra che la procedura ha eseguito il proprio compito correttamente
-- SELECT * FROM Giornata WHERE insieme_squadre = @insieme;

/*
 * Nel seguito si utilizza la funzione is_campo_casa per
 * mostrarne il funzionamento per tutti e tre i casi di interesse;
 */
-- SELECT is_campo_casa('P-0', 'S-0'); -- Falso
-- SELECT is_campo_casa('P-0', 'S-1'); -- Vero
-- SELECT is_campo_casa('P-0', 'S-2'); -- Errore

/*
 * SEZIONE DEDICATA ALLE INTERROGAZIONI
 */
 
/*
 * Nella successiva sezione si mostrano alcune query che potrebbero 
 * essere appetibili per l'utilizzatore del database.
 */
 
-- Trovare nome e cognome di tutti i giocatori aventi numero 10 nella squadra con la quale
-- partecipano ad una fase e che hanno segnato un gol in almeno 2 partite distinte nella fase
-- SELECT nome, cognome FROM 
-- 	 (SELECT nome, cognome, COUNT(gol) AS partite_a_segno FROM 
-- 		(SELECT DISTINCT nome, cognome, tessera, insieme_squadre
-- 		FROM Giocatore G, Rosa R 
-- 		WHERE G.tessera = R.giocatore
-- 		AND numero_maglia = 10) 
-- 	 AS Anag, Statistiche AS S
-- 	 WHERE Anag.tessera = S.giocatore
-- 	 AND Anag.insieme_squadre = 
-- 		(SELECT insieme FROM partite_torneo 
-- 		WHERE partita = S.partita_giocata)
-- 	 AND S.gol > 0
--  	GROUP BY nome, cognome)
-- AS giocatori_prolifici
-- WHERE partite_a_segno >= 2;
    
-- Trovare tessera, nome e cognome dei giocatori non assegnati a nessuna squadra che attualmente partecipa ad un torneo in corso
-- SELECT DISTINCT tessera, nome, cognome FROM Giocatore G, Rosa R
-- WHERE G.tessera = R.giocatore
-- AND R.squadra IN 
-- 	   (SELECT squadra FROM squadra_iscrizioni
--     WHERE torneo IN 
-- 		(SELECT codice FROM Torneo 
-- 		WHERE codice NOT IN 
-- 			(SELECT torneo FROM tornei_terminati)));
            
-- Trovare tutte le squadre che hanno o potrebbero avere come colore sociale il bianco ma che non abbiano il colore blu
-- SELECT * FROM Squadra WHERE (colori IS NULL OR colori LIKE '%bianco%') AND colori NOT LIKE '%blu%';