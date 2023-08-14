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
    categoria	ENUM('M','F','N') NOT NULL,		-- 
    tipologia	ENUM('5','7','11') NOT NULL,
    
    UNIQUE (nome, categoria, tipologia, edizione)
);

CREATE TABLE IF NOT EXISTS Fase(
    codice		VARCHAR(6) 				-- F-xxxx
				PRIMARY KEY,
    torneo		VARCHAR(5) NOT NULL
				REFERENCES Torneo(codice)
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	nome		VARCHAR(40) NOT NULL,
    modalita	ENUM('Girone','Eliminazione') NOT NULL,
    scontri		TINYINT UNSIGNED 
				DEFAULT 1 NOT NULL,
    
	UNIQUE(torneo, nome)		
);

CREATE TABLE IF NOT EXISTS Insieme_squadre(
    codice		VARCHAR(7) 				-- I-xxxxx
				PRIMARY KEY,
    fase		VARCHAR(6) NOT NULL,
    nome		CHAR(1) DEFAULT NULL, 	-- Lettera dell'alfabeto 
										-- o NULL per le fasi con un solo insieme di squadre
	FOREIGN KEY (fase)
		REFERENCES Fase(codice)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	UNIQUE (fase, nome)
);

CREATE TABLE IF NOT EXISTS Campo(
	codice		VARCHAR(5) 
				PRIMARY KEY,
    nome		VARCHAR(50) NOT NULL,
    telefono 	VARCHAR(15) DEFAULT NULL,
    comune		VARCHAR(30) NOT NULL,
    via			VARCHAR(40) NOT NULL,
    civico		SMALLINT UNSIGNED NOT NULL,
    UNIQUE(comune, via, civico),
    UNIQUE (nome, comune)
);

CREATE TABLE IF NOT EXISTS Squadra(
    codice			VARCHAR(8) PRIMARY KEY,
	nome			VARCHAR(40) NOT NULL,
    tipologia		ENUM('5','7') NOT NULL,
    categoria		CHAR(1) NOT NULL,
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
    
    FOREIGN KEY (insieme_squadre)
		REFERENCES Insieme_squadre(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (squadra)
		REFERENCES Squadra(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	PRIMARY KEY (insieme_squadre, squadra)
);

CREATE TABLE IF NOT EXISTS Giornata(
    codice		VARCHAR(7) PRIMARY KEY,
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
	nome			VARCHAR(20) NOT NULL,
    cognome			VARCHAR(20) NOT NULL,
    genere			CHAR(1) NOT NULL,
    data			DATE NOT NULL,
    squadra			MEDIUMINT UNSIGNED,
    numero			TINYINT UNSIGNED,
    
    UNIQUE (nome, cognome, data),
    UNIQUE (squadra, numero)
);

CREATE TABLE IF NOT EXISTS Rosa(
	squadra		VARCHAR(8),
    giocatore	SMALLINT UNSIGNED,
    numero_maglia TINYINT UNSIGNED,
    
    PRIMARY KEY(squadra, giocatore),
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
	nome			VARCHAR(20) NOT NULL,
    cognome			VARCHAR(20) NOT NULL,
    genere			CHAR(1) NOT NULL,
    data			DATE NOT NULL,
    
	UNIQUE (nome, cognome, data)
);

CREATE TABLE IF NOT EXISTS Partita(
    codice				VARCHAR(9) PRIMARY KEY,
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

CREATE TABLE IF NOT EXISTS Statistiche_partita(
	giocatore			SMALLINT UNSIGNED NOT NULL,
    partita				VARCHAR(9) NOT NULL,
    gol					TINYINT UNSIGNED,
    assist				TINYINT UNSIGNED,
	ammonizioni			ENUM ('0','1','2'),
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


