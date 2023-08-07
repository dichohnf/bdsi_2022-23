DROP DATABASE IF EXISTS bdsi_prog2023;
CREATE DATABASE IF NOT EXISTS bdsi_prog2023;
USE bdsi_prog2023;

CREATE TABLE IF NOT EXISTS Torneo(
    codice		SMALLINT UNSIGNED -- sarebbe da cambiare i codici e mettere caratteri. I Codici dei tornei T1, T2... quelli delle fase F1, F2...
				PRIMARY KEY
                AUTO_INCREMENT,
	nome		VARCHAR(30) NOT NULL,
    categoria	CHAR(1) NOT NULL,
    tipologia	ENUM('5','7') NOT NULL,
    edizione	TINYINT UNSIGNED,
    
    UNIQUE (nome, categoria, tipologia, edizione)
)ENGINE=INNODB;



CREATE TABLE IF NOT EXISTS Fase(
    torneo		SMALLINT UNSIGNED NOT NULL,
	nome		VARCHAR(40) NOT NULL,
    tipo		ENUM('Girone','Eliminazione') NOT NULL,
    turni		TINYINT UNSIGNED DEFAULT NULL,
    scontri		TINYINT UNSIGNED DEFAULT NULL,
    
	PRIMARY KEY(torneo, nome),
	FOREIGN KEY (torneo)
		REFERENCES Torneo(codice)
		ON DELETE CASCADE
		ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS Insieme_squadre(
    codice		SMALLINT UNSIGNED
				PRIMARY KEY
                AUTO_INCREMENT,
    torneo		SMALLINT UNSIGNED NOT NULL,
    fase		VARCHAR(40) NOT NULL,
    nome		CHAR(1),
    
	FOREIGN KEY (torneo, fase)
		REFERENCES Fase(torneo, nome)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	UNIQUE (torneo, fase, nome)
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS Campo(
	nome		VARCHAR(50) NOT NULL,
    telefono 	VARCHAR(15),
    comune		VARCHAR(30) NOT NULL,
    via			VARCHAR(40) NOT NULL,
    civico		SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY(comune, via, civico),
    UNIQUE (nome, comune)
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS Squadra(
    codice			MEDIUMINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	nome			VARCHAR(40) NOT NULL,
    tipologia		ENUM('5','7') NOT NULL,
    categoria		CHAR(1) NOT NULL,
    colori			VARCHAR(30) DEFAULT NULL,
	campo_nome		VARCHAR(50) DEFAULT NULL,
    campo_comune	VARCHAR(30) DEFAULT NULL,

    FOREIGN KEY (campo_nome, campo_comune)
		REFERENCES Campo(nome, comune)
		ON DELETE SET NULL
        ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS Appartenenza(
	insieme_squadre 	SMALLINT UNSIGNED,
    squadra 			MEDIUMINT UNSIGNED,
    
    PRIMARY KEY (insieme_squadre, squadra),
    FOREIGN KEY (insieme_squadre)
		REFERENCES Insieme_squadre(codice)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (squadra)
		REFERENCES Squadra(codice)
		ON DELETE CASCADE
        ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS Giornata(
    codice		INT PRIMARY KEY AUTO_INCREMENT,
    torneo		SMALLINT UNSIGNED NOT NULL,
	fase		VARCHAR(40) NOT NULL,
	numero		TINYINT UNSIGNED NOT NULL,
    
    -- PRIMARY KEY (numero, fase, torneo), -- introduciamo anche qua un codice? Senno' partita diventa grossa
    UNIQUE (torneo, fase, numero),
    FOREIGN KEY (torneo, fase)
		REFERENCES Fase(torneo, nome)
)ENGINE=INNODB;

# CREATE TABLE IF NOT EXISTS Tessera (
# 	numero	MEDIUMINT UNSIGNED PRIMARY KEY AUTO_INCREMENT
# )ENGINE=INNODB;



CREATE TABLE IF NOT EXISTS Giocatore(
	tessera			MEDIUMINT UNSIGNED PRIMARY KEY, 
	nome			VARCHAR(20) NOT NULL,
    cognome			VARCHAR(20) NOT NULL,
    genere			CHAR(1) NOT NULL,
    nascita			DATE NOT NULL,
    squadra			MEDIUMINT UNSIGNED,
    numero			TINYINT UNSIGNED,
    
    UNIQUE (nome, cognome, nascita),
    UNIQUE (squadra, numero)
# 	FOREIGN KEY (tessera)
# 		REFERENCES Tessera(numero)
#         ON DELETE NO ACTION
#         ON UPDATE NO ACTION
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS Arbitro(
	tessera			MEDIUMINT UNSIGNED PRIMARY KEY, 
	nome			VARCHAR(20) NOT NULL,
    cognome			VARCHAR(20) NOT NULL,
    genere			CHAR(1) NOT NULL,
    nascita			DATE NOT NULL,
    
	UNIQUE (nome, cognome, nascita)
)ENGINE=INNODB;

DELIMITER $$ 
CREATE TRIGGER assegnazione_tessera
BEFORE INSERT ON Giocatore
FOR EACH ROW BEGIN
	DECLARE temp MEDIUMINT UNSIGNED;
	SELECT max(tessera) INTO temp FROM(SELECT(tessera) FROM Giocatore UNION SELECT(tessera) FROM Arbitro) ultima_tessera;
    SET NEW.tessera = temp + 1;
END $$
DELIMITER ;

CREATE TABLE IF NOT EXISTS Partita_programmata(
    codice				INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	squadra_casa		MEDIUMINT UNSIGNED NOT NULL,
    squadra_ospite		MEDIUMINT UNSIGNED NOT NULL,
    giornata			INT NOT NULL,
    data 				DATETIME NOT NULL,
    campo_nome			VARCHAR(50) NOT NULL,
    campo_comune		VARCHAR(30) NOT NULL,
    direzione			MEDIUMINT UNSIGNED NOT NULL, 
    
    UNIQUE (squadra_casa, squadra_ospite, giornata),
    UNIQUE (squadra_casa, squadra_ospite, data),
    FOREIGN KEY(squadra_casa)
		REFERENCES Squadra(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY(squadra_ospite)
		REFERENCES Squadra(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY(giornata)
		REFERENCES Giornata(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY(campo_nome, campo_comune)
		REFERENCES Campo(nome, comune)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	FOREIGN KEY(direzione)
		REFERENCES Arbitro(tessera)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
		-- CHECK (squadra_casa <> squadra_ospite )
        -- trigger quando inseriscpo punteggio devo avere campo not null E ADRBITRO NOT NULL
        
)ENGINE=INNODB;

CREATE TABLE Punteggio_partita(
	partita_programmata	INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	gol_casa			TINYINT UNSIGNED NOT NULL,
    gol_ospiti			TINYINT UNSIGNED NOT NULL
)ENGINE=INNODB;

DELIMITER $$
    
CREATE TRIGGER aggiunta_partita
BEFORE INSERT ON Partita
FOR EACH ROW 
BEGIN
	SELECT (squadra_casa, squadra_ospite) AS coppie_squadre_partita FROM Partita WHERE (Partita.giornata = NEW.giornata);
    IF (NEW.squadra_casa IN (select squadra_casa from coppia_squadre_partita) OR NEW.sqadra_ospite IN (select squadra_trasferta from coppia_squadre_partita)) THEN 
    SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = CONCAT("La squadra ha gia una partita programmata nella giornata ", NEW.giornata);
	END IF;
END $$

show errors $$



# CREATE TRIGGER aggiornamento_punteggio
# BEFORE UPDATE ON partita
# FOR EACH ROW
# null_check: BEGIN
# 	IF (NEW>gol_casa <> NULL AND NEW.gol_ospiti <> NULL)
#     THEN LEAVE null_check;
# 	ELSEIF (NEW.direzione <> NULL and NEW.direzione <> ''
# 		AND  NEW.campo_comune <> NULL AND NEW.campo_comune <> ''
# 		AND  NEW.campo_casa <> NULL AND NEW.campo_casa <> '')
# 		THEN LEAVE null_check;
# 	END IF;
# END null_check $$

DELIMITER ;
	

	

CREATE TABLE IF NOT EXISTS Statistiche_partita(
	giocatore			MEDIUMINT UNSIGNED NOT NULL,
    partita				INT UNSIGNED NOT NULL,
    gol					TINYINT UNSIGNED,
    assist				TINYINT UNSIGNED,
	ammonizioni			ENUM ('0','1','2'),
    espulsione			BOOL,
	espulsione_giornate	TINYINT UNSIGNED,
    
    FOREIGN KEY(giocatore)
		REFERENCES Giocatore(tessera)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
	-- bisogna controllare anche che il giocatore appartenga a una delle due squadre TRIGGER
	FOREIGN KEY(partita)
		REFERENCES Partita(codice)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
)ENGINE=INNODB;

LOAD DATA LOCAL
INFILE '/home/madict/Documenti/Unifi Informatica/2_Anno/2_Semestre/bdsi/progetto/Popolamento/Torneo.csv'
INTO TABLE Torneo
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
(nome, tipologia, categoria);
    
LOAD DATA LOCAL
INFILE '/home/madict/Documenti/Unifi Informatica/2_Anno/2_Semestre/bdsi/progetto/Popolamento/Fase.csv'
INTO TABLE Fase
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(nome, tipo, turni, scontri, torneo);

LOAD DATA LOCAL
INFILE '/home/madict/Documenti/Unifi Informatica/2_Anno/2_Semestre/bdsi/progetto/Popolamento/Insieme_squadre.csv'
INTO TABLE Insieme_squadre
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
(torneo, fase, nome);

LOAD DATA LOCAL
INFILE '/home/madict/Documenti/Unifi Informatica/2_Anno/2_Semestre/bdsi/progetto/Popolamento/Campo.csv'
INTO TABLE Campo
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
(nome, telefono, comune, via, civico);

LOAD DATA LOCAL
INFILE '/home/madict/Documenti/Unifi Informatica/2_Anno/2_Semestre/bdsi/progetto/Popolamento/Squadre.csv'
INTO TABLE Squadra
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
(nome, tipologia, categoria, colori, campo_nome, campo_comune);

LOAD DATA LOCAL
INFILE '/home/madict/Documenti/Unifi Informatica/2_Anno/2_Semestre/bdsi/progetto/Popolamento/Appartenenza.csv'
INTO TABLE Appartenenza
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(insieme_squadre, squadra);

LOAD DATA LOCAL
INFILE '/home/madict/Documenti/Unifi Informatica/2_Anno/2_Semestre/bdsi/progetto/Popolamento/Giornata.csv'
INTO TABLE Giornata
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(torneo, fase, numero);
