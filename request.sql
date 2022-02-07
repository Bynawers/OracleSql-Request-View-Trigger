-- INSERTIONS

insert into client values(1, 'un', 'rue de 1 ain','paris',75001,0101010101,'francaise');
insert into client values (2, 'deux' , '2 rue de 1 ecole' , 'nice' , 06004, 0502030406, ' chinoise' ) ;
insert into client values(3,'trois','3 rue de troyes','lille',59003,0303030303,'francaise');
insert into client values(4,'quatre','4 rue du coq','strasbourg',67004,0304040404,'anglaise');

insert into commande values(97111, '27-mai-73',1,24000);
insert into commande values(97002,'17-oct-72',1,25000);
insert into commande values(97003, '08-aou-91',3,6900); 
insert into commande values(97004,'31-jan-93',2,654);

insert into lignecommande values(97004,23,24534,324,2,213); 
insert into lignecommande values(96003,65,24534,423,6,628); 
insert into lignecommande values(97007,35,93456,3756,9,123); 
insert into lignecommande values(97002,2,53421,945,3,521);

insert into produit values(24534,'tournevis',900,560); 
insert into produit values(93456,'marteau',900,56); 
insert into produit values(43908,'rouge a levres',100,23); 
insert into produit values(38056,'pull',400,279);


-- MISES A JOUR

update client set nom = upper(nom);
update client set nom = lower(nom) where nationalite='francaise';
update commande set prixtotal=(2*prixtotal) where (ladate<'01-jan-92');


-- SUPPRESSIONS

delete from client where nationalite='francaise'; 

delete from client where clientId in ( 
      select clientId 
      from commande 
      where ladate < '01-jan-90');



-- REQUETES d'INTERROGATION

-- 1- Liste des clients ? 
select * 
from client;

-- 2- liste clients francais ?

select * 
from client 
where lower(nationalite)='francaise';

-- 3. liste clients francais par ordre alphabetique?

select nom, adresse, ville, departement
from client 
where lower(nationalite)='francaise' 
order by nom asc;

-- 4. numero des clients americains situes a paris?

select clientId 
from client 
where lower(nationalite)='americaine' and lower(ville)='paris';

insert into client 
values (5,'cinq','5 rue du club','paris',75005,0105050505,'americaine');

-- 5- nom clients francais ou anglais:

select nom,nationalite 
from client 
where lower(nationalite) in ('francaise','anglaise');

-- 6- num commandes entre 31/12/92 et 31/12/93?

select commandeId,ladate 
from commande 
where ladate between '31-dec-92' and '31-dec-93';

-- 7. nom des clients et numero des commandes qu'ils passent?

select client.nom,commande.commandeId 
from client,commande 
where client.clientid=commande.clientid;

insert into commande values(97005,'10-sep-97',10,321);

-- 8. code des fabricants qui fabriquent le produit x le moins cher?

select p.fabricantid
from produit p
where p.prixproduit in (
	select min(q.prixproduit)
	from produit q
	where q.description='tournevis')
and p.description = 'tournevis';

select p.fabricantid
from produit p, (select description, min(prixproduit) as min
			from Produit
			group by description) Temp
where p.description = temp.description
and p.prixproduit = temp.min;


insert into produit values(24535,'tournevis',800,200);
insert into produit values (100, 'pull', 800, 200);

-- 9- noms fabricants qui fabriquent le produit x le moins cher?

select f.nom
from fabricant f,produit p
where p.prixproduit in (select min(q.prixproduit)
						from produit q
						where q.description='tournevis')
and p.description = 'tournevis'
and p.fabricantId=f.fabricantId;

insert into fabricant values (800,'hilti');

-- 10- pour chaque description produit, prix moyen et prix max ?

select description,avg(prixproduit),max(prixproduit) 
from produit 
group by description;

-- 11. idem 10 mais au moins 2 fabricants par produit?

select description,avg(prixproduit),max(prixproduit) 
from produit 
group by description 
having count(produit.fabricantId)>1;


-- 12-pour chaque type de produit, donner le nom du fabricant qui le frabrique au plus bas prix?

select p.description,f.nom,p.prixproduit
from produit p,fabricant f
where p.fabricantId=f.fabricantId
and p.prixproduit in	(	select min(q.prixproduit)
							from produit q
							where p.description = q.description);

-- 13. nom des clients qui n ont pas passe de commandes?

	select c.nom
	from client c
	where not exists(	select *
						from commande co
						where co.clientid = c.clientid);

-- 14. couples des numeros de numeros de clients differents?

select p.clientId,q.clientId 
from client p,client q 
where p.clientId != q.clientId;

select p.clientId,q.clientId 
from client p,client q 
where p.clientId  < q.clientId;

-- 15- 

select distinct nom from Client where Adresse is null;
insert into client values (6,'six',null, null,null,null,null);

-- 16- 

Update Client set Adresse='adresse' where Adresse is null;

-- 17
select distinct Client.ClientId,Produit.ProduitId,sum(LigneCommande.quantite)
from Client,Produit,LigneCommande,Commande
where Client.ClientId=Commande.ClientId
and LigneCommande.CommandeId=Commande.CommandeId
and LigneCommande.ProduitId=Produit.ProduitId
group by Client.ClientId,Produit.ProduitId;


-- TP3:
Create view vue_tp3 (ProduitId,somme,moyenne) as (
      select ProduitId, sum(Quantite),avg (quantite) 
      from LigneCommande 
      group by ProduitId);

Create view vraie_moyenne (moy) as (
select avg(moyenne) 
from vue_tp3);

create view mieux_vendus as (
	select ProduitId
	from Produit
	where ProduitId in (select ProduitId
		from vue_tp3,vraie_moyenne
		where vue_tp3.somme>vraie_moyenne.moy));
