SELECT clientid
FROM Client cl
WHERE not exists(select *
				 FROM produit p
				 WHERE not exists (	select *
				 					FROM COMMANDE co, lignecommande l
				 					WHERE co.commandeid = l.commandeid
				 					AND co.clientid = cl.clientid
				 					AND l.produitid = p.produitid));
-- division avec calcul d'agrégats
SELECT cl.clientid
FROM client cl, commande co, lignecommande l
WHERE cl.clientid = co.clientid
AND co.commandeid = l.commandeid
GROUP BY cl.clientid
HAVING count(distinct l.produitid) = select count(*) from produit);


-- Exerice 1 : 

Set serverout on

prompt 'donner identifiant client'
accept ClientId


DECLARE 
	n Number;
	Id Number := &ClientId;
	message varchar(40);

BEGIN 
	SELECT COUNT(CommandeId) INTO n 
	FROM COMMANDE WHERE ClientId = Id;
	
	IF n = 0 THEN 
		message := 'pas de commandes';
	ELSE 
		message := 'il y a ' || n || ' commandes pour le client ' || Id;
	END IF;

	INSERT INTO RESULTAT VALUES ( 0, message );
	DBMS_OUTPUT.put_line(message);
END;
/


-- Exercice 2  

prompt 'donner identifiant client'
accept ClientId

DECLARE 
	montant Number;
	moy Number;
	Id client.clientid%type := &ClientId;;
	red Number;
	v varchar(40);

BEGIN 
	SELECT SUM(PRIXTOTAL) INTO montant 
	FROM COMMANDE WHERE ClientId = Id;

	SELECT ville INTO v 
	FROM CLIENT WHERE ClientId = Id;

	SELECT AVG(temp.montant) INTO moy
	FROM ( SELECT ClientId, SUM(PRIXTOTAL) as montant
		  FROM CLIENT 
		  WHERE ville = v ) temp;
	
	DBMS_OUTPUT.put_line('Prix total des commandes du client ' || Id || ' : ' || montant );	
	DBMS_OUTPUT.put_line('Montant moyen des commandes faites dans la ville ' || v || ' où habite le client ' || Id || ' : ' || moy );

	IF montant > moy THEN red := 0.90;
	ELSE red := 0.95;
	END IF;

	UPDATE COMMANDE SET PRIXTOTAL = PRIXTOTAL*red WHERE ClientId = Id;
END;
/



-- Exercice 3 

prompt 'donner la valeur de n'
accept num

DECLARE 
	n NUMBER := &num ;
	CURSOR c IS SELECT CommandeId, Date_com, PrixTotal 
		    	FROM COMMANDE 
		    	ORDER BY Date_com;
    Id commande.commandeid%type;
	da commande.date_com%type;
	pt commande.prixtotal%type;
	message varchar(60);
	N_TOO_BIG EXCEPTION;

BEGIN 
	OPEN c;
	LOOP 
		FETCH c INTO Id, da, pt;
		n := n - 1;
		exit when ( n=0 or c%notfound)
	END LOOP;
	
	if (c%found) then 
		message := Id || ' # ' || da || ' # ' || pt;
		INSERT INTO RESULTAT VALUES ( 0, message );
		DBMS_OUTPUT.put_line(message);

		FETCH c INTO Id, da, pt;
		if (c%found) then
				message := Id || ' # ' || da || ' # ' || pt;
				INSERT INTO RESULTAT VALUES ( 0, message );
				DBMS_OUTPUT.put_line(message);
		end if;
	ELSE RAISE N_TOO_BIG;
	end if;

	CLOSE c;

	EXCEPTION 
	WHEN N_TOO_BIG THEN
		INSERT INTO RESULTAT VALUES ( 0, 'ERREUR : Le n donné est plus grand que le nombre de commandes !' );
END;
/

-- Exercice 4 

DECLARE
	CURSOR c IS 
		SELECT CommandeId, PrixTotal FROM Commande;
	CURSOR l(cde commande.commandid%type) IS 
		SELECT SUM(itemtotal)
		FROM LigneCommande 
		WHERE CommandeId = cde;

	ID commande.commandeid%type;
	PT commande.prixtotal%type;
	PC NUMBER(15,2) := 0;
	message varchar2(60);
	
BEGIN 
	OPEN c;

	LOOP 
		FETCH c INTO ID, PT;
		EXIT WHEN c%NOTFOUND;
		
		open l(ID);
		fetch l into pc;
		close l;

		message := 'Cde : ' || ID || ', Prix Total : ' || PT || ', Prix Total Calculé :' || PC;
		INSERT INTO Resultat VALUES ( 0, message );
	
	END LOOP;

	CLOSE c;

END;
/

-- exo 4 sans curseur paramétré possible et préférable
DECLARE
	CURSOR c IS 
		SELECT CommandeId, PrixTotal 
		FROM Commande;

	ID commande.commandeid%type;
	PT commande.prixtotal%type;
	PC NUMBER(15,2) := 0;
	message varchar2(60);
	
BEGIN 
	OPEN c;

	LOOP 
		FETCH c INTO ID, PT;
		EXIT WHEN c%NOTFOUND;
		
		SELECT SUM(itemtotal) INTO PC
		FROM LigneCommande 
		WHERE CommandeId = ID;

		message := 'Cde : ' || ID || ', Prix Total : ' || PT || ', Prix Total Calculé :' || PC;
		INSERT INTO Resultat VALUES ( 0, message );
	END LOOP;

	CLOSE c;

END;
/



-- Exercice 5 

DECLARE
	CURSOR c IS 
		SELECT CommandeId, PrixTotal 
		FROM Commande
		FOR UPDATE OF PrixTotal;

	ID commande.commandeid%type;
	PT commande.prixtotal%type;
	PC NUMBER(15,2) := 0;
	message varchar2(60);
BEGIN
	
	OPEN c;

	LOOP 
		FETCH c INTO ID, PT;
		EXIT WHEN c%NOTFOUND;
		
		SELECT SUM(itemtotal) INTO PC
		FROM LigneCommande 
		WHERE CommandeId = ID;

		if (PC != PT) THEN 	UPDATE Commande SET PrixTotal = PC
					 		WHERE current of c;
		END IF;
		
	END LOOP;

	CLOSE c;
END;
/



-- Exercice 6 

CREATE PROCEDURE tri_clients IS 
DECLARE 
	CURSOR c IS 
		SELECT cl.ClientId, SUM (co.prixtotal) as total
		FROM Client cl, commande co
		WHERE cl.clientid = co.clientid
		GROUP BY cl.ClientId 
		ORDER BY total, cl.ClientId desc;

		Id commande.commandeid%type;
		tot number(15,2);
  		    
BEGIN
	OPEN c; 

	LOOP
		FETCH c INTO Id, tot;
		INSERT INTO Resultat VALUES (0, 'ClientId : ' || Id || ', PrixCommande : ' || tot );
		EXIT WHEN c%NOTFOUND;
	END LOOP;

	CLOSE c;
END;
/

CREATE OR REPLACE FUNCTION Id_max_com() RETURN client.ClientId%TYPE IS		
DECLARE
	CURSOR c IS 
		SELECT cl.ClientId, SUM (co.prixtotal) as total
		FROM Client cl, commande co
		WHERE cl.clientid = co.clientid
		GROUP BY cl.ClientId 
		ORDER BY total, cl.ClientId desc;
	Id client.clientid%type := NULL;

BEGIN
	OPEN c;

	FETCH c INTO Id;
    
	CLOSE c;

	RETURN Id;
END;
/


CREATE or REPLACE PACKAGE exo7 IS
	FUNCTION Id_max_com() RETURN Client.ClientId%TYPE;

	PROCEDURE tri_clients;

END;
/


CREATE or REPLACE PACKAGE BODY exo7 IS
	DECLARE 
	CURSOR c IS 
		SELECT cl.ClientId, SUM (co.prixtotal) as total
		FROM Client cl, commande co
		WHERE cl.clientid = co.clientid
		GROUP BY cl.ClientId 
		ORDER BY total, cl.ClientId desc;

	FUNCTION Id_max_com() RETURN client.ClientId%TYPE IS		
		DECLARE

			Id client.clientid%type := NULL;

			BEGIN
				OPEN c;
				FETCH c INTO Id;
				CLOSE c;

				RETURN Id;
			END;
	END;

	PROCEDURE tri_clients IS 
		DECLARE 

			Id commande.commandeid%type;
			tot number(15,2);
  		    
		BEGIN
			OPEN c; 

			LOOP
				FETCH c INTO Id, tot;
				INSERT INTO Resultat VALUES (0, 'ClientId : ' || Id || ', PrixCommande : ' || tot );
				EXIT WHEN c%NOTFOUND;
			END LOOP;

			CLOSE c;
		END;
	END;
	/


-- TRIGGERS 
-- exo1 
alter table commande add constraint ch_1 check (commandeid between 1 and 999);

-- exo2
alter table client add constraint ch_2 check (nationalite in ('GB', 'E', 'B', 'US') OR (nationalite = 'FR' and adresse is nou null));

-- visualiser les constraintes en consultant le dictionnaire
select table_name, constraint_name, constraint_type
from user_constraints
order by table_name;

select constraint_name, constraint_type
from user_constraints
where table_name = 'CLIENT';

-- exo3 et exo 5 integres
create or replace trigger t_exo3 before insert on commande for each row
	declare 
		nbmax commande.commandid%type := 0;
	begin
		select max(commandeid) into nbmax
		from commande;
		:new.commandeid := nbmax + 1;
		:new.date_com := sysdate;
		:new.prixtotal := 0;
	end;
/

-- visualisationd des triggers
desc user_triggers
select *
from user_triggers
where table_name = 'COMMANDE';

insert into commande values (null, null, 1, null);

-- exo 4
create or replace trigger t_exo4 before insert on client for each row
	declare
		dpt client.departement%type := NULL;
	begin
		select distinct departement into dpt 
		from Client
		where ville = :new.ville;
		if (SQL%FOUND and dpt != :new.departement) then 
					raise_application_error(-20002,'violation de dependance fonctionnelle, insertion impossible');
		end if;
	end;
/

-- exo 5 :

-- exo 6 

create or replace trigger t_exo61 before update on lignecommande for each row
	begin
		raise_application_error(-20004,'pas de MAJ possible, veuillez supprimer puis insérer à nouveau');
	end;
/
create or replace trigger t_exo62 before insert on lignecommande for each row
	begin
		:new.itemtotal := :new.prix * :new.quantite;
	end;
/
create or replace trigger t_exo63 after insert or delete on lignecommande for each row
	begin
	if (inserting) then 
		update commande set prixtotal = prixtotal + :new.itemtotal
		where commandeid = :new.commandeid;
	end if;
	if (deleting) then
		update commande set prixtotal = prixtotal - :old.itemtotal
		where commandeid = :old.commandeid;
	end if;
	end;
/ 

-- exo7
alter table commande add remise number(2);

create or replace trigger t_exo7 after update(prixtotal) on commande for each row
	declare 
		montant number(15,2) := 0;
	begin
		select sum (prixtotal) into montant
		from commande
		where ClientId = :old.clientid;
		if (montant > 1000) then 	update commande set remise = 10
									where commandeid = :old.commandeid;
		end if;
	end;
/

-- exo8

-- exo 9 
create table statistics ( 
	table_name varchar(25) primary key,
	ins integer,
	upd integer,
	del integer);
insert into statistics values ('PRODUIT',0,0,0);
insert into statistics values ('COMMANDE',0,0,0);

create or replace trigger Monitoring_Produit after insert or update or delete on produit for each row
	begin
	if inserting then 	update statistics set ins = ins + 1
						where table_name = 'PRODUIT';
	end if;
	if deleting then 	update statistics set del = del + 1
						where table_name = 'PRODUIT';
	end if;
	if updating then 	update statistics set upd = upd + 1
						where table_name = 'PRODUIT';
	end if;
	end;
/

create or replace trigger Monitoring_Commande after insert or update or delete on commande for each row
	begin
	if inserting then 	update statistics set ins = ins + 1
						where table_name = 'COMMANDE';
	end if;
	if deleting then 	update statistics set del = del + 1
						where table_name = 'COMMANDE';
	end if;
	if updating then 	update statistics set upd = upd + 1
						where table_name = 'COMMANDE';
	end if;
	end;
/