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
    categoria	ENUM('M','F','N') NOT NULL,
    tipologia	ENUM('5','7','11') NOT NULL,
    
    UNIQUE (nome, categoria, tipologia, edizione)
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
    tipologia		ENUM('5','7') NOT NULL,
    categoria		ENUM('M','F','N') NOT NULL,
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
    giocatore	SMALLINT UNSIGNED,
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
    arbitro				SMALLINT UNSIGNED NOT NULL,
    
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
    gol					TINYINT UNSIGNED 	DEFAULT 0,
    assist				TINYINT UNSIGNED 	DEFAULT 0,
	ammonizioni			ENUM ('0','1','2') 	DEFAULT '0',
	espulsione_giornate	TINYINT UNSIGNED 	DEFAULT 0,
    
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
 * La successiva vista rappresenta l'inisieme di tutti i tesserati.
 *Occorre per operare la creazione di una nuova tessera.
 */
CREATE VIEW tesserati
(tessera, nome, cognome, data, genere) AS 
(SELECT * FROM Giocatore UNION SELECT * FROM Arbitro);
	
/*
 * SEZIONE DEDICATA AI TRIGGER
 * La sezione successiva definisce i trigger per il controllo 
 * dei vincoli non esprimibili tramite i costrutti del linguaggio.
 * I trigger relativi agli inserimenti (i primi della lista) 
 * condividono una sezione relativa al controllo del formato del codice.
 * Non è stato possibile implementare una procedura unica per tutti
 * i trigger per limitazioni del linguaggio: non è possibile
 * ustilizzare in questi i meccanismi dinamici di SQL (es. prepared functions)
 * per il riconoscimento della tabella da cui eseguire la ricerca
 * dell'indice minimo del codice.
 * I trigger per gli inserimenti quindi controllano il formato del 
 * codice e, qualora non sia corretto, lo assegnano individuano l'indice 
 * minimo tra quelli disponibili. (Non è detto che le istanze inserite 
 * cronologicamente dopo abbiano codice maggiore). In caso di assegnazione
 * viene restituito uno warning affinchè sia evidente l'avvenimento.
 */
 
DELIMITER $$

CREATE TRIGGER torneo_inserimento BEFORE INSERT ON Torneo
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255); 
	IF NEW.codice NOT LIKE 'T-%' OR NEW.codice IS NULL 
	THEN
		SET NEW.codice = CONCAT('T-', COALESCE((SELECT MIN(CAST(SUBSTRING(codice FROM 3) AS DECIMAL)) FROM Torneo) + 1, '0'));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
    END IF;
END$$

CREATE TRIGGER fase_inserimento BEFORE INSERT ON Fase
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255);
	IF NEW.codice != 'F-%' OR NEW.codice IS NULL 
	THEN
		SET NEW.codice = CONCAT('F-', COALESCE((SELECT MIN(CAST(SUBSTRING(codice FROM 3) AS DECIMAL)) FROM Fase) + 1, '0'));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER insieme_squadre_inserimento BEFORE INSERT ON Insieme_squadre
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255);
	IF NEW.codice != 'I-%' OR NEW.codice IS NULL 
	THEN
		SET NEW.codice = CONCAT('I-', COALESCE((SELECT MIN(CAST(SUBSTRING(codice FROM 3) AS DECIMAL)) FROM Insieme_squadre) + 1, '0'));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER campo_inserimento BEFORE INSERT ON Campo
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255);
	IF NEW.codice != 'C-%' OR NEW.codice IS NULL 
	THEN
		SET NEW.codice = CONCAT('C-', COALESCE((SELECT MIN(CAST(SUBSTRING(codice FROM 3) AS DECIMAL)) FROM Campo) + 1, '0'));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER squadra_inserimento BEFORE INSERT ON Squadra
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255);
	IF NEW.codice != 'S-%' OR NEW.codice IS NULL 
	THEN
		SET NEW.codice = CONCAT('S-', COALESCE((SELECT MIN(CAST(SUBSTRING(codice FROM 3) AS DECIMAL)) FROM Squadra) + 1, '0'));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER giornata_inserimento BEFORE INSERT ON Giornata
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255);
	IF NEW.codice != 'G-%' OR NEW.codice IS NULL 
	THEN
        SET NEW.codice = CONCAT('G-', COALESCE((SELECT MIN(CAST(SUBSTRING(codice FROM 3) AS DECIMAL)) FROM Giornata) + 1, '0'));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER giocatore_inserimento BEFORE INSERT ON Giocatore
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255);
	IF NEW.tessera IS NULL 
	THEN 
		SET NEW.tessera = COALESCE((SELECT MIN(tessera) FROM tesserati) + 1, 0);
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con tessera: ", NEW.tessera);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER arbitro_inserimento BEFORE INSERT ON Arbitro
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255);
	IF NEW.tessera IS NULL 
	THEN 
		SET NEW.tessera = COALESCE((SELECT MIN(tessera) FROM tesserati) + 1, 0);
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con tessera: ", NEW.tessera);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

CREATE TRIGGER Partita_inserimento BEFORE INSERT ON Squadra
FOR EACH ROW
BEGIN
	DECLARE warnmsg VARCHAR(255);
	IF NEW.codice != 'P-%' OR NEW.codice IS NULL 
	THEN
		SET NEW.codice = CONCAT('P-', COALESCE((SELECT MIN(CAST(SUBSTRING(codice FROM 3) AS DECIMAL)) FROM Partita) + 1, '0'));
		SET warnmsg = CONCAT("Il codice inserito non risulta accettabile. Istanza inserita con codice: ", NEW.codice);
		SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = warnmsg; 
	END IF;
END$$

DELIMITER ;


/*
 * SEZIONE DEDICATA AGLI INSERIMENTI
 */

# Si mostra un inserimento manuale da script (tabella Torneo)
INSERT INTO Torneo(nome, tipologia, categoria, edizione)
	VALUES	('Firenze Inverno','7','N',1),
			('Firenze Estate','5','M',1);
            
INSERT INTO Giocatore (tessera, nome, cognome, data, genere)
	VALUES  (NULL, 'Pippo', 'deVez', '2021-10-15', 'M'),
			(NULL, 'Luca', 'Micaio', '2022-02-27', 'N');



/*
 * SEZIONE DEDICATA ALLE INTERROGAZIONI
 */
 
 # SELECT * FROM Torneo ORDER BY CAST(SUBSTRING(codice FROM 3) AS DECIMAL);
 # SELECT * FROM Giocatore;
 