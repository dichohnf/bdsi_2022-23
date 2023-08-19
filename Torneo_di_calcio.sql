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
    codice		VARCHAR(7) PRIMARY KEY,		-- G-xxxxx
	fase		VARCHAR(6) NOT NULL,
	numero		TINYINT UNSIGNED NOT NULL,
    
    UNIQUE (fase, numero),
    FOREIGN KEY (fase)
		REFERENCES Fase(codice)
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
    gol					TINYINT UNSIGNED DEFAULT 0,
    assist				TINYINT UNSIGNED DEFAULT 0,
	ammonizioni			TINYINT UNSIGNED DEFAULT 0,
	espulsione_giornate	TINYINT UNSIGNED DEFAULT 0,
    
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
		(SELECT fase FROM Giornata WHERE 
			codice IN (SELECT giornata FROM Partita) AND													-- Giornata con almeno una partita definita
            codice NOT IN (SELECT giornata FROM Partita WHERE gol_casa IS NULL OR gol_ospite IS NULL))));	-- Giornata con nessuna partita (NOT IN) non terminata (IS NULL) 
    
/*
 * SEZIONE DEDICATA AI TRIGGER
 * La sezione successiva definisce i trigger per il controllo 
 * dei vincoli non esprimibili tramite i costrutti del linguaggio.
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

CREATE TRIGGER TR_INS_Giornata BEFORE INSERT ON Giornata
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(127);
    DECLARE idx_prev_libero INT;
	DECLARE idx_next_libero INT;
    DECLARE n_giornate_cur 	INT UNSIGNED;
    DECLARE n_giornate_exp 	INT UNSIGNED;

    # Controllo codice
	IF NEW.codice NOT LIKE 'G-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Giornata HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Giornata)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Giornata HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Giornata)) AS idx_libero_next;
        SET NEW.codice = CONCAT('G-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
        SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg;
	END IF;
        
    # Controllo vincoli del numero di giornate in una fase
    SET n_giornate_cur = ((SELECT COUNT(codice) FROM Giornata WHERE fase = NEW.fase) +1);			-- somma 1 per comprendere anche la giornata che sta venendo inserita
    IF (SELECT modalita FROM Fase WHERE codice = NEW.fase) = 'Girone'
    THEN SET n_giornate_exp = (
		((SELECT COUNT(squadra) AS n_giornate_exp FROM Raggruppamento WHERE insieme_squadre = 
			(SELECT codice FROM Insieme_squadre WHERE fase = NEW.fase)
		) -1) * (SELECT scontri FROM Fase WHERE codice=NEW.fase)									-- sottratto 1 dato il vincolo #giornate = #squadre -1
	);
	ELSE SET n_giornate_exp = (																		-- Caso: Fase.modalita = 'Eliminazione'
		SELECT FLOOR(LOG2((SELECT COUNT(squadra) FROM Raggruppamento WHERE insieme_squadre = 
			(SELECT codice FROM Insieme_squadre WHERE fase = NEW.fase)))) * (SELECT scontri FROM Fase WHERE codice=NEW.fase)
	);
	END IF;
	IF (n_giornate_cur < n_giornate_exp)																-- Se il numero di giornate presenti (current) è inferiore al numero di giornate attese (expected) viene segnalato tramite warning
	THEN
		SET warnmsg = CONCAT("Giornate insufficienti. Occorrono ulteriori ", (n_giornate_exp - n_giornate_cur), " giornate per il completamento della fase");
		SIGNAL SQLSTATE '01001' SET MESSAGE_TEXT = warnmsg;
    END IF;
END$$

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

/*
 * Le tessere sono assegnate seguendo l'ordine cronologico. Le prime tessere
 * possiedono numeri bassi.
 */

CREATE TRIGGER TR_INS_Partita BEFORE INSERT ON Partita
FOR EACH ROW
BEGIN
	DECLARE idx_prev_libero INT;
    DECLARE idx_next_libero INT;
	DECLARE warnmsg VARCHAR(127);
    -- Controllo formato codice
	IF NEW.codice NOT LIKE 'P-_%' OR NEW.codice IS NULL 
	THEN
		SELECT MIN(idx) INTO idx_prev_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) -1 AS idx FROM Partita HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Partita)) AS idx_libero_prev;
        SELECT MIN(idx) INTO idx_next_libero FROM (SELECT CAST(SUBSTRING(codice FROM 3) AS DECIMAL) +1 AS idx FROM Partita HAVING idx NOT IN (SELECT CAST(SUBSTRING(codice FROM 3) AS UNSIGNED) FROM Partita)) AS idx_libero_next;
        SET NEW.codice = CONCAT('P-', IF((idx_prev_libero < 0) OR (idx_next_libero <= idx_prev_libero ), idx_next_libero, 0));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
    -- Controllo vincolo: squadre giocanti diverse
    IF NEW.squadra_casa = NEW.squadra_ospite
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Squadre uguali. Le partite devono essere formate da due squadre distinte.", MYSQL_ERRNO=1000;
    END IF;
END$$

CREATE TRIGGER TR_INS_Statistiche BEFORE INSERT ON Statistiche
FOR EACH ROW
BEGIN 
	DECLARE errmsg VARCHAR(127);
    #Controllo ammonizioni appartenenti a {0,1,2}
    IF NEW.ammonizioni NOT IN (0,1,2)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="Numero ammonizioni fuori dal dominio {0, 1, 2}.", MYSQL_ERRNO=1001;
    END IF;
END $$

DELIMITER ;


/*
 * SEZIONE DEDICATA AGLI INSERIMENTI
 */

# Inserimento manuale da script (tabella Torneo)

INSERT INTO Torneo(nome, tipologia, genere, edizione)
VALUES	('Firenze Inverno','7','N',1),
		('Firenze Estate','5','M',1);
            
INSERT INTO Fase(torneo, nome, modalita, scontri)
VALUES ('T-0', 'Eliminazione unico', 'Eliminazione', 1);

INSERT INTO Campo (nome, telefono, comune, via, civico)
VALUES ('Campetto', '055055055', 'Firenze', 'via senza fine', 8);

INSERT INTO Squadra(nome, tipologia, genere, campo)
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
VALUES ('F-0', NULL);

INSERT INTO Raggruppamento (insieme_squadre, squadra)
VALUES ('I-0','S-0'),
	   ('I-0','S-1'),
       ('I-0','S-2'),
	   ('I-0','S-3'),
       ('I-0','S-4'),
       ('I-0','S-5');
       
INSERT INTO Rosa (squadra, giocatore, numero_maglia)
VALUES ('S-0', 0, 1),
	   ('S-1', 1, 2);
       
LOAD DATA LOCAL INFILE './Popolamento/Giornata.csv'
INTO TABLE Giornata
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(codice, fase, numero);

INSERT INTO Partita (giornata, giorno, ora, squadra_casa, squadra_ospite, arbitro, campo, gol_casa, gol_ospite)
VALUES ('G-0', '2023-08-19', '18:06', 'S-0', 'S-1', '2', 'C-0', 1, 0);

INSERT INTO Statistiche (partita, giocatore, gol, assist, ammonizioni , espulsione_giornate)
VALUES ('P-0', '0', 1, 1, NULL, NULL);

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
# SELECT * from tesseramenti;
# SELECT * FROM Arbitro;


 
 