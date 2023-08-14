DROP DATABASE IF EXISTS `bdsi_prog2023`;
CREATE DATABASE IF NOT EXISTS `bdsi_prog2023`;

USE bdsi_prog2023;

SET GLOBAL local_infile = 'ON';

CREATE TABLE IF NOT EXISTS Torneo(
    codice		VARCHAR(5)
				PRIMARY KEY,
	nome		VARCHAR(30) NOT NULL,
    edizione	TINYINT UNSIGNED NOT NULL,
    categoria	CHAR(1) NOT NULL,
    tipologia	ENUM('5','7') NOT NULL,
    
    UNIQUE (nome, categoria, tipologia, edizione)
);

CREATE TABLE IF NOT EXISTS Fase(
    codice		VARCHAR(6) 
				PRIMARY KEY,
    torneo		VARCHAR(5) NOT NULL,
	nome		VARCHAR(40) NOT NULL,
    modalita	ENUM('Girone','Eliminazione') NOT NULL,
    scontri		TINYINT UNSIGNED 
				DEFAULT 1 NOT NULL,
    
	UNIQUE(torneo, nome),
	FOREIGN KEY (torneo)
		REFERENCES Torneo(codice)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Insieme_squadre(
    codice		VARCHAR(7) 
				PRIMARY KEY,
    fase		VARCHAR(6) NOT NULL,
    nome		CHAR(1) DEFAULT NULL, -- Lettera dell'alfabeto 
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

INSERT INTO Torneo (codice, nome, tipologia, categoria, edizione)
	VALUES	('1','Firenze Inverno','7','N',1),
			('2','Firenze Estate','5','M',1);

LOAD DATA LOCAL
	INFILE './Popolamento/Fase.in'
    INTO TABLE Fase
    FIELDS TERMINATED BY '|'
		OPTIONALLY ENCLOSED BY '+'
	IGNORE 3 LINES
	(nome, modalita, scontri, torneo);

LOAD DATA LOCAL
	INFILE './Popolamento/Insieme_squadre.csv'
    INTO TABLE Insieme_squadre
    FIELDS TERMINATED BY ','
		OPTIONALLY ENCLOSED BY '"'
	(fase, nome);

LOAD DATA LOCAL
	INFILE './Popolamento/Campo.csv'
    INTO TABLE Campo
    FIELDS TERMINATED BY ','
		OPTIONALLY ENCLOSED BY '"'
	(nome, telefono, comune, via, civico);


LOAD DATA LOCAL
INFILE './Popolamento/Squadre.csv'
INTO TABLE Squadra
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
(nome, tipologia, categoria, colori, campo);

LOAD DATA LOCAL
	INFILE './Popolamento/Raggruppamento.csv'
    INTO TABLE Raggruppamento
    FIELDS TERMINATED BY ','
		OPTIONALLY ENCLOSED BY '"'
	IGNORE 1 LINES
	(insieme_squadre, squadra);

LOAD DATA LOCAL
	INFILE './Popolamento/Giornata.csv'
    INTO TABLE Giornata
    FIELDS TERMINATED BY ','
		OPTIONALLY ENCLOSED BY '"'
	IGNORE 1 LINES
	(fase, numero);
    
DELIMITER $$

CREATE VIEW squadra_giocatori
	(codice_squadra,nome_squadra,codice_giocatore,cognome_giocatore,nome_giocatore,numero_maglia)
    AS SELECT S.codice,S.nome,G.tessera,G.cognome,G.nome,G.numero
		FROM Squadra S, Giocatore G
        WHERE S.codice = G.squadra$$

CREATE VIEW abbinamenti_round_robin
	(squadra_casa,squadra_ospite)
    AS SELECT squadre_casa.squadra, squadre_ospite.squadra
		FROM Raggruppamento squadre_casa, Raggruppamento squadre_ospite
		WHERE squadre_casa.insieme_squadre = squadre_ospite.insieme_squadre AND squadre_casa.squadra != squadre_ospite.squadra$$

CREATE PROCEDURE assegna_codice(IN tipo_codice ENUM('T','I','S','G','P','C'), INOUT codice VARCHAR(10))
	NOT DETERMINISTIC
	CASE tipo_codice
    WHEN 'T' THEN SET codice = concat('T-',codice); -- Torneo
    WHEN 'F' THEN SET codice = concat('F-',codice); -- Fase
    WHEN 'I' THEN SET codice = concat('I-',codice); -- Insieme squadre
    WHEN 'S' THEN SET codice = concat('S-',codice); -- Squadra
    WHEN 'G' THEN SET codice = concat('G-',codice); -- Giornata
    WHEN 'P' THEN SET codice = concat('P-',codice); -- Partita
    WHEN 'C' THEN SET codice = concat('C-',codice); -- Campo
    END CASE$$

CREATE FUNCTION tessera_assegnata()
RETURNS SMALLINT UNSIGNED
NOT DETERMINISTIC NO SQL
BEGIN
	DECLARE temp SMALLINT UNSIGNED;
	SELECT max(tessera) INTO temp FROM (SELECT (tessera) FROM Giocatore UNION SELECT (tessera) FROM Arbitro) T;
	RETURN temp + 1;
END$$

CREATE TRIGGER aggiunto_codice_torneo
BEFORE INSERT ON Torneo
FOR EACH ROW
BEGIN
	IF NEW.codice != 'T-%' OR NEW.codice IS NULL
	THEN CALL assegna_codice('T', NEW.codice);
	END IF;
END$$

CREATE TRIGGER aggiunto_codice_fase
AFTER INSERT ON Fase
FOR EACH ROW
BEGIN
	IF NEW.codice = NULL
	THEN CALL assegna_codice('F', NEW.codice);
	END IF;
END$$

CREATE TRIGGER aggiunto_codice_insieme_squadre
AFTER INSERT ON Insieme_squadre
FOR EACH ROW
BEGIN
	IF NEW.codice = NULL
	THEN CALL assegna_codice('I', NEW.codice);
	END IF;
END$$

CREATE TRIGGER aggiunto_codice_squadra
AFTER INSERT ON Squadra
FOR EACH ROW
BEGIN
	IF NEW.codice = NULL
	THEN CALL assegna_codice('S', NEW.codice);
	END IF;
END$$

CREATE TRIGGER aggiunto_codice_giornata
AFTER INSERT ON Giornata
FOR EACH ROW
BEGIN
	IF NEW.codice = NULL
	THEN CALL assegna_codice('G', NEW.codice);
	END IF;
END$$

CREATE TRIGGER aggiunto_codice_partita
AFTER INSERT ON Partita
FOR EACH ROW
BEGIN
	IF NEW.codice = NULL
	THEN CALL assegna_codice('P', NEW.codice);
	END IF;
END$$

CREATE TRIGGER squadre_uguali
BEFORE INSERT ON Partita
FOR EACH ROW
	IF NEW.squadra_casa = NEW.squadra_ospite
		THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Partita non registrata: una squadra non puo' affrontare se stessa";
	END IF$$

CREATE TRIGGER aggiunto_codice_campo
AFTER INSERT ON Campo
FOR EACH ROW
BEGIN
	IF NEW.codice = NULL
	THEN CALL assegna_codice('C', NEW.codice);
	END IF;
END$$

CREATE TRIGGER aggiunta_partita
BEFORE INSERT ON Partita
FOR EACH ROW 
BEGIN
  DECLARE specialty CONDITION FOR SQLSTATE '45000';
  DECLARE errormsg VARCHAR(255);
  IF (NEW.squadra_casa
		IN (SELECT squadra_casa 
			FROM (SELECT (squadra_casa, squadra_ospite) FROM Partita WHERE (Partita.giornata = NEW.giornata)) p) OR NEW.squadra_ospite IN (SELECT squadra_trasferta FROM coppia_squadre_partita p))
    THEN SET errormsg = CONCAT("La squadra ha gia' una partita programmata nella giornata ", NEW.giornata);
    SIGNAL specialty
    set MESSAGE_TEXT = errormsg;
  END IF;
END $$

CREATE TRIGGER aggiunta_statistiche
BEFORE INSERT ON Statistiche_partita
FOR EACH ROW
BEGIN
	DECLARE specialty CONDITION FOR SQLSTATE '45000'; 
	DECLARE squadra_casa VARCHAR(40);
    DECLARE squadra_ospite VARCHAR(40);
	DECLARE errormsg VARCHAR(255);
	IF ((SELECT gol_casa FROM Partita WHERE NEW.partita=Partita.codice) IS NULL OR (SELECT gol_ospite FROM Partita WHERE NEW.partita=Partita.codice) IS NULL)
	THEN
    BEGIN
		SELECT nome FROM Squadra WHERE codice = (SELECT squadra_casa FROM Partita WHERE NEW.partita=Partita.codice) INTO squadra_casa;
        SELECT nome FROM Squadra WHERE codice = (SELECT squadra_ospite FROM Partita WHERE NEW.partita=Partita.codice) INTO squadra_ospite;
		SET errormsg = CONCAT("La partita ",squadra_casa,"-",squadra_ospite," non e' ancora stata giocata");
        SIGNAL specialty
		SET MESSAGE_TEXT = errormsg;
	END;
    END IF;
END $$

CREATE FUNCTION partita_giocata(partita CHAR(10))
	RETURNS boolean
    NOT DETERMINISTIC NO SQL
    BEGIN
		IF((SELECT gol_casa FROM Partita WHERE partita=Partita.codice) IS NULL OR (SELECT gol_ospite FROM Partita WHERE partita=Partita.codice) IS NULL)
		THEN RETURN FALSE;
        ELSE
        RETURN TRUE;
        END IF;
    END $$

CREATE PROCEDURE correggi_codice(INOUT codice VARCHAR(10), IN tipo ENUM('T','I','S','G','C','A','P'))
    DETERMINISTIC
	BEGIN
		SET codice = CONCAT(tipo,'-',codice);
	END $$

CREATE TRIGGER maglia_assegnata
BEFORE INSERT ON Giocatore
FOR EACH ROW
BEGIN
	DECLARE maglia_libera TINYINT;
    SET maglia_libera = 0;
	IF NEW.squadra != NULL AND NEW.numero = NULL
		THEN
		REPEAT
			SET maglia_libera = maglia_libera + 1;
			UNTIL maglia_libera NOT IN (SELECT G.numero FROM Giocatore G WHERE G.squadra = NEW.squadra)
		END REPEAT;
        SET NEW.numero = maglia_libera;
	END IF;
END$$

CREATE TRIGGER codice_torneo_corretto
BEFORE INSERT ON Torneo
FOR EACH ROW
IF substring(new.codice,0,2) != 'T-'
	THEN CALL correggi_codice(codice,'T');
END IF $$

CREATE TRIGGER codice_fase_corretto
BEFORE INSERT ON Fase
FOR EACH ROW
IF substring(new.codice,0,2) != 'F-'
	THEN CALL correggi_codice(codice,'F');
END IF $$

CREATE TRIGGER codice_insieme_squadre_corretto
BEFORE INSERT ON Insieme_squadre
FOR EACH ROW
IF substring(new.codice,0,2) != 'I-'
	THEN CALL correggi_codice(codice,'I');
END IF $$

CREATE TRIGGER codice_squadra_corretto
BEFORE INSERT ON Squadra
FOR EACH ROW
IF substring(new.codice,0,2) != 'S-'
	THEN CALL correggi_codice(codice,'S');
END IF $$

CREATE TRIGGER codice_giornata_corretto
BEFORE INSERT ON Giornata
FOR EACH ROW
IF substring(new.codice,0,2) != 'G-'
	THEN CALL correggi_codice(codice,'G');
END IF $$

CREATE TRIGGER codice_partita_corretto
BEFORE INSERT ON Partita
FOR EACH ROW
IF substring(new.codice,0,2) != 'P-'
	THEN CALL correggi_codice(codice,'P');
END IF $$

CREATE TRIGGER codice_campo_corretto
BEFORE INSERT ON Campo
FOR EACH ROW
IF substring(new.codice,0,2) != 'C-'
	THEN CALL correggi_codice(codice,'C');
END IF $$

CREATE TRIGGER tessera_giocatore_corretta
BEFORE INSERT ON Giocatore
FOR EACH ROW
SET NEW.tessera = tessera_assegnata()$$

CREATE TRIGGER tessera_arbitro_corretta
BEFORE INSERT ON Arbitro
FOR EACH ROW
SET NEW.tessera = tessera_assegnata()$$

CREATE TRIGGER iscritto_giocatore_genere_update
BEFORE UPDATE ON Giocatore
FOR EACH ROW
BEGIN
DECLARE iscrizione_errore CONDITION FOR SQLSTATE '45000';
IF NEW.squadra != NULL AND 'N' != (SELECT S.categoria FROM Squadra S WHERE NEW.squadra = S.codice) AND NEW.genere != (SELECT S.categoria FROM Squadra S WHERE NEW.squadra = S.codice)
THEN SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = "Errore: Tentativo d'iscrizione giocatore a squadra illegale (incompatibilita' genere giocatore e categoria squadra)";
END IF;
END$$

CREATE VIEW partite_disputate
(codice, squadra_casa, squadra_ospite, giornata, data, ora, gol_casa, gol_ospite, campo, arbitro)
AS SELECT * FROM Partita P WHERE partita_giocata(P.codice)$$

CREATE FUNCTION partita_numero_giornata(partita VARCHAR(9))
RETURNS TINYINT UNSIGNED
DETERMINISTIC NO SQL
RETURN (SELECT G.numero FROM Partita P, Giornata G WHERE P.Giornata = G.codice)$$

CREATE VIEW diffidati
(codice, nome, cognome, squadra) AS
SELECT codice, nome, cognome, squadra
	FROM (SELECT giocatore AS codice
		FROM (SELECT codice AS squadra FROM partite_disputate) S NATURAL JOIN Statistiche_partita
        GROUP BY giocatore HAVING SUM(ammonizioni >= 4)) G NATURAL JOIN (SELECT tessera AS codice, nome, cognome, squadra FROM Giocatore) G2$$

CREATE FUNCTION ultima_giornata_giocata()
RETURNS TINYINT UNSIGNED
NOT DETERMINISTIC NO SQL
RETURN (SELECT MAX(numero) FROM partite_disputate NATURAL JOIN (SELECT codice AS giornata, numero FROM Giornata) G)$$

CREATE VIEW squalificati
(codice, nome, cognome, squadra) AS
SELECT codice, nome, cognome, squadra
	FROM diffidati UNION ((SELECT tessera AS codice, nome, cognome, squadra FROM Giocatore NATURAL JOIN 
		(SELECT giocatore AS codice, partita, espulsione_giornate FROM Statistiche_partita S 
		WHERE espulsione_giornate >= ultima_giornata_giocata() + 1 + partita_numero_giornata(S.partita)) AS espulsioni_dirette)) $$

CREATE TRIGGER iscritto_giocatore_genere_insert
BEFORE INSERT ON Giocatore
FOR EACH ROW
BEGIN
DECLARE iscrizione_errore CONDITION FOR SQLSTATE '45000';
IF NEW.squadra != NULL AND 'N' != (SELECT S.categoria FROM Squadra S WHERE NEW.squadra = S.codice) AND NEW.genere != (SELECT S.categoria FROM Squadra S WHERE NEW.squadra = S.codice)
THEN SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = "Errore: Tentativo d'iscrizione giocatore a squadra illegale (incompatibilita' genere giocatore e categoria squadra)";
END IF;
END$$

CREATE TRIGGER genere_squadre_torneo
BEFORE INSERT ON Raggruppamento
FOR EACH ROW
BEGIN
DECLARE categoria_torneo CHAR(1);
DECLARE errormsg VARCHAR(255);
SET errormsg = concat('La squadra non puo essera associata all\'insieme ', NEW.insieme_squadre, ' poichè il gruppo partecipa ad un torneo di categoria ', genere_torneo);
Set categoria_torneo = (SELECT categoria from Torneo where Torneo.fase IN (select codice from Fase join Insieme_squadre where Insieme_squadre.fase = Fase.codice AND Insieme_squadre.codice = NEW.insieme_squadre));
  IF  genere_torneo <> (SELECT categoria from squadra where Squadra.codice = NEW.squadra)
    then SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = errormsg;
  END IF;
END $$

CREATE TRIGGER genere_squadre_torneo_update
BEFORE UPDATE ON Raggruppamento
FOR EACH ROW
BEGIN
DECLARE categoria_torneo CHAR(1);
DECLARE errormsg VARCHAR(255);
SET errormsg = concat('La squadra non puo essera associata all\'insieme ', NEW.insieme_squadre, ' poichè il gruppo partecipa ad un torneo di categoria ', genere_torneo);
Set categoria_torneo = (SELECT categoria from Torneo where Torneo.fase IN (select codice from Fase join Insieme_squadre where Insieme_squadre.fase = Fase.codice AND Insieme_squadre.codice = NEW.insieme_squadre));
  IF  genere_torneo <> (SELECT categoria from squadra where Squadra.codice = NEW.squadra)
	then SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = errormsg;
  END IF;
END $$

CREATE TRIGGER corretto_punteggio
BEFORE INSERT ON Statistiche_partita
FOR EACH ROW
BEGIN
DECLARE risultato_parziale CONDITION FOR SQLSTATE '01000';
DECLARE risultato_inconsistente CONDITION FOR SQLSTATE '45000';
DECLARE codice_squadra VARCHAR(8);
DECLARE gol_squadra TINYINT UNSIGNED;
DECLARE gol_giocatori TINYINT UNSIGNED;
DECLARE assist_giocatori TINYINT UNSIGNED;
SET codice_squadra = (SELECT squadra FROM Giocatore G WHERE NEW.giocatore = G.tessera);

IF nome_squadra IN (SELECT squadra_casa FROM Partita P WHERE P.codice = NEW.partita)
	THEN SET gol_squadra = (SELECT gol_casa FROM Partita P WHERE NEW.partita = P.codice);
ELSE IF codice_squadra IN (SELECT squadra_ospite FROM Partita P WHERE P.codice = NEW.partita)
	THEN SET gol_squadra = (SELECT gol_ospite FROM Partita P WHERE NEW.partita = P.codice);
END IF;

SET gol_giocatori = (SELECT SUM(gol) FROM (SELECT giocatore, gol FROM Statistiche_giocatore S WHERE NEW.partita = S.partita) gol_gioc_partita
	NATURAL JOIN (SELECT tessera AS giocatore FROM Giocatore G WHERE codice_squadra = G.squadra) gioc_squadra);
SET assist_giocatori = (SELECT SUM(assist) FROM (SELECT giocatore, assist FROM Statistiche_giocatore S WHERE NEW.partita = S.partita) assist_gioc_partita
	NATURAL JOIN gioc_squadra);
    
IF gol_giocatori > gol_squadra 
	THEN SIGNAL risultato_inconsistente SET MESSAGE_TEXT = 'Gol dei giocatori inconsistenti con il risultato della partita';
ELSEIF gol_giocatori < gol_squadra 
	THEN SIGNAL risultato_parziale SET MESSAGE_TEXT = 'Statistiche della partita ancora incomplete';
END IF;
IF assist_giocatori > gol_squadra 
	THEN SIGNAL risultato_inconsistente SET MESSAGE_TEXT = 'Assist dei giocatori inconsistenti con il risultato della partita';
ELSEIF assist_giocatori < gol_squadra 
	THEN SIGNAL risultato_parziale SET MESSAGE_TEXT = 'Statistiche della partita ancora incomplete';
END IF;
END IF; -- QUESTO SECONDO END IF NON CAPISCO PERCHE' MI OBBLIGA A METTERLO!!!
END$$

CREATE TRIGGER controllo_numero_giornate
BEFORE INSERT ON Giornata
FOR EACH ROW
BEGIN
  DECLARE warn_msg VARCHAR(255);
    Declare modalita_fase  ENUM('Girone', 'Eliminazione');
  Declare totale_giornate int;
    declare numero_squadre int;
    declare scontri int;
    
    set modalita_fase = (select modalita from Fase where NEW.fase = Fase.codice);
    set totale_giornate = (select COUNT(codice) from Partita where Partita.giornata = NEW.codice);
    set numero_squadre = (select COUNT(squadra) from Raggruppamento where Raggruppamento.insieme_squadre = 
              (select codice from Insieme_squadre where Insieme_squadre.fase = New.fase));
    set scontri = (select scontri from Fase where Fase.codice = NEW.fase);
    set warn_msg = CONCAT(totale_giornate, " no corrispondono al numero di giornate per la fase ", NEW.fase, " con modalita ", modalita_fase, " e numero di scontri ", scontri);
    IF modalita_fase = 'Girone'
    THEN
        If totale_giornate <> (select ((numero_squadre - 1) * scontri))
        then 
      set warn_msg = CONCAT(totale_giornate, " no corrispondono al numero di giornate per la fase ", NEW.fase);
      signal sqlstate '01000'
            set message_text = warn_msg;
    END IF;
  ELSE
    IF totale_giornate <> (select (log2(numero_squadre) - 1))
    then
      signal sqlstate '01000'
      set message_text = warn_msg;
    END IF;
  END IF;
END $$

##################################################################################
# LA SUCCESSIVA SEZIONE MANTIENE IL TRIGGER PER CONTROLLARE CHE IN OGNI GIORNATA #
# SIA PRESENTE L'ESATTO NUMERO DI PARTITE            				   			 #
##################################################################################

CREATE TRIGGER controllo_numero_partite
BEFORE INSERT ON Partita
FOR EACH ROW
BEGIN
  DECLARE warn_msg VARCHAR(255);
    DECLARE totale_partite INT;
  DECLARE numero_squadre INT;
    SET totale_partite = (SELECT COUNT(codice) FROM Giornata WHERE Giornata.codice = NEW.giornata);
    SET numero_squadre = (SELECT count(squadra) FROM Raggruppamento WHERE Raggruppamento.insieme_squadre =
              (SELECT codice FROM Insieme_squadre WHERE Insieme_squadre.fase = 
                (SELECT fase FROM Giornata WHERE Giornata.codice = NEW.giornata)));
    SET warn_msg = CONCAT("Il numero di partite non e` accettabile visto il numero di squadre");
    IF (totale_partite <> (SELECT numero_squadre / 2))
    THEN SIGNAL SQLSTATE '01000'
    SET MESSAGE_TEXT= warn_msg;
  END IF;
END $$

####################################################################################
# LA SUCCESSIVA SEZIONE RAPPRESENTA LA QUERY PER IL CALCOLO DELLA CLASSIFICA       #
# INSERIRE IL CODICE DEL GIRONE E LA GIORNATA ALLA QUALE SI DESIDERA LA CLASSIFICA #
# NELLE VARIABILI @girone E @giornata             					   			   #
# LA CLASSIFICA HA SENSO SOLO PER FASI A GIRONI, QUELLE AD ELIMINAZIONE NON        #
# POSSIEDONO CLASSIFICA                 						   				   #
####################################################################################

DELIMITER ;
SET @insieme = 'G-00001';  #INSERIRE IL CODICE DELL'INSIEME DI SQUADRE (OVVERO GIRONE) DI CUI SI DESIDERA CALCOLARE LA CLASSIFICA

CREATE FUNCTION insieme()
RETURNS CHAR(7)
DETERMINISTIC NO SQL
RETURN @insieme;

CREATE VIEW squadre_insieme
(squadra) AS
(SELECT squadra FROM Raggruppamento WHERE Raggruppamento.insieme_squadre = insieme());

SET @giornata= 5;    #INSERIRE IL NUMERO DELLA GIORNATA DI CUI CALCOLARE LA CLASSIFICA E DECOMMENTARE L'ISTRUZIONE

CREATE FUNCTION giornata()
RETURNS INT
DETERMINISTIC NO SQL
RETURN @giornata;

CREATE VIEW partite_giornate_precedenti
(codice, squadra_casa, squadra_ospite, giornata, giorno, ora, gol_casa, gol_ospite, campo, arbitro) AS 
(SELECT * FROM Partita WHERE giornata IN 
  (SELECT codice FROM Giornata WHERE numero < giornata() AND fase = 
    (SELECT fase FROM Insieme_squadre WHERE codice = insieme())
  )
);

CREATE VIEW punti_vittorie 
(squadra, punti) AS
SELECT squadra, COUNT(squadra) * 3
FROM squadre_insieme SG JOIN partite_giornate_precedenti PG 
WHERE (PG.squadra_casa = SG.squadra AND gol_casa > gol_ospite) OR (PG.squadra_ospite = SG.squadra AND gol_casa < gol_ospite)
GROUP BY squadra;

CREATE VIEW punti_pareggi
(squadra, punti) AS
SELECT squadra, COUNT(squadra)
FROM squadre_insieme SG JOIN partite_giornate_precedenti PG 
WHERE (PG.squadra_casa = SG.squadra AND gol_casa = gol_ospite) OR (PG.squadra_ospite = SG.squadra AND gol_casa = gol_ospite)
GROUP BY squadra;

CREATE VIEW classifica
(squadra, punti) AS
SELECT squadra, SUM(punti) FROM
(
  select * from punti_vittorie
  UNION
    select * from punti_pareggi 
)tot
GROUP BY squadra
ORDER BY punti;

####################################################
#    SEZIONE STATISTICHE SINGOLI GIOCATORI     #
#LE SEGUENTI VIEW, ASSIEME ALLA VIEW squarde_girone#
#  CONCORRONO ALLA RESTITUZIONE DELLE CLASSIFICHE  #
#    DEI GIOCATORI NELLA FASE IN CUI E` INSERITO   #
#       L'INSIEME DI SQUADRE SPECIFICATO           #
####################################################

SET @insieme = 'G-00001';

CREATE VIEW giocatori_girone
(tessera, nome, cognome, genere, data, squadra, numero) AS 
SELECT * FROM Giocatore G WHERE G.squadra IN 
  (SELECT squadra FROM Raggruppamento R WHERE R.insieme_squadre = insieme());
CREATE VIEW tot_statistiche_giocatori
(tessera, nome, cognome, genere, data, squadra, numero, gol, assist, ammonizioni, espulsione_giornate) AS 
SELECT tessera, nome, cognome, genere, data, squadra, numero, SUM(gol) as tot_gol, SUM(assist) as tot_assist, SUM(ammonizioni) as tot_ammon, SUM(espulsione_giornate) as tot_gior_espul
FROM (giocatori_girone G  JOIN Statistiche_partita ST)
WHERE (ST.giocatore = G.tessera)
AND (ST.partita IN ( SELECT partita FROM partite_giornate_precedenti ))
GROUP BY tessera;

CREATE VIEW capo_cannonieri
(tessera, nome, cognome, squadra, gol) AS
SELECT tessera, nome, cognome, squadra, gol  FROM tot_statistiche_giocatori
ORDER BY gol;

CREATE VIEW capo_assistmen
(tessera, nome, cognome, squadra, assist) AS
SELECT tessera, nome, cognome, squadra, assist FROM tot_statistiche_giocatori
ORDER BY assist;

CREATE VIEW giocatori_piu_ammoniti
(tessera, nome, cognome, squadra, ammonizioni) AS
SELECT tessera, nome, cognome, squadra, ammonizioni FROM tot_statistiche_giocatori
ORDER BY ammonizioni;

CREATE VIEW giocatori_piu_espulsi
(tessera, nome, cognome, squadra, tot_gior_espulsione) AS
SELECT tessera, nome, cognome, squadra, espulsione_giornate FROM tot_statistiche_giocatori
ORDER BY espulsione_giornate;

################################
#SEZIONE INTERROGAZIONI#
#1- Trovare i numeri 10 di un insieme di squadre#
#2- Giocatori i cui la cui seconda lettera  del nome è una A e i cui cognomi terminano per E #
#3- Squadre iscritte a piu fasi del Torneo 'Firenze Estate' #

# SELECT tessera, nome, cognome, data, squadra 
# FROM Giocatore G 
# WHERE G.numero = 10 
# AND G.squadra IN 
# (
#   SELECT squadra from squadre_insieme
# );

# SELECT * 
# FROM Giocatore 
# WHERE nome = "_A%"
# AND cognome = "%E";

# SELECT * FROM Squadra 
# WHERE codice IN 
# (
#   SELECT squadra FROM Raggruppamento 
#     WHERE insieme_squadre IN 
#     (
#     SELECT codice from Insieme_squadre 
#         WHERE fase IN 
#         (
#       SELECT codice FROM Fase 
#             WHERE torneo = 
#             (
#         SELECT codice FROM Torneo WHERE nome = 'Firenze Estate'
#       )
#     )
#   )
# );

#########################################################
# PROCEDURA DI INSERIMENTO FASI        				    #
# Procedura esemplificativa di inserimenti senza codici #
#########################################################

DELIMITER $$
CREATE PROCEDURE inserimento_fase
(IN nome_torneo VARCHAR(30), IN tipologia ENUM('5','7'), IN categoria CHAR(1), IN edizione TINYINT UNSIGNED, IN nome_fase VARCHAR(40))
DETERMINISTIC
BEGIN
  DECLARE codice_torneo CHAR(5);
    SET codice_torneo = (SELECT codice FROM Torneo T WHERE T.nome = nome_torneo AND T.tipologia = tipologia AND T.categoria = categoria AND T.edizione = edizione);
    INSERT INTO Fase(torneo, nome)
    VALUE (codice_torneo, nome_fase);
END $$

DELIMITER ;

-- SET @pipoVar = CAST('PipoVez' AS CHAR(7));
-- SELECT correggi_codice(@pipoVar);

/*
-- LOAD DATA LOCAL
-- 	INFILE './Popolamento/Tessere'
--     INTO TABLE Tessere
--     FIELDS TERMINATED BY ','
-- 		OPTIONALLY ENCLOSED BY '"'
--         ();

-- DA DEFINIRE ANCORA!!!!!!

LOAD DATA LOCAL
	INFILE './Popolamento/Giocatore.csv'
    INTO TABLE Giocatore
    FIELDS TERMINATED BY ','
		OPTIONALLY ENCLOSED BY '"'
        IGNORE 1 LINES
        (insieme_squadre, squadra);



-- SELECT * FROM Torneo	order by codice;
*/