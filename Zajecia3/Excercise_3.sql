--1--
--Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana
--pomiędzy 2018 a 2019)

select *,st_asText(tabA.geom),st_asText(tabB.geom),tabA.height,tabB.height from  t2019_kar_buildings as tabB
left join t2018_kar_buildings as tabA on tabA.polygon_id = tabB.polygon_id
where tabA.polygon_id is null
OR (tabA.height != tabB.height)
OR NOT st_equals(tabA.geom, tabB.geom)

--rozw2
select *,st_asText(tabA.geom),st_asText(tabB.geom),tabA.height,tabB.height from  t2019_kar_buildings as tabB
left join t2018_kar_buildings as tabA on tabA.polygon_id = tabB.polygon_id
WHERE (tabA.height is distinct from tabB.height)
OR (tabA.geom is distinct from tabB.geom)
--warunek is null jest niekonieczny bo zawiera sie w dwoch pozostalych, is distinct from traktuje null jako osobna wartosc

--2--
--Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
--wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.

WITH buildings  AS (
		select tabB.geom as geom from  t2019_kar_buildings as tabB
		left join t2018_kar_buildings as tabA on tabA.polygon_id = tabB.polygon_id
		where tabA.polygon_id is null
		OR (tabA.height != tabB.height)
		OR NOT st_equals(tabA.geom, tabB.geom)),
	points AS (
		select tableB.*  from t2019_kar_poi_table as tableB
		left join t2018_kar_poi_table as tableA on tableA.poi_id = tableB.poi_id
		where tableA.poi_id is null )
select t.type,count(*) from (
	select distinct points.* from buildings,points
	where st_distance(st_transform(buildings.geom,3857), st_transform(points.geom,3857))<500) as t
group by t.type

--3--
--Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
--T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.
create table streets_reprojected as
select gid,link_id,st_name,ref_in_id,nref_in_id,func_class,speed_cat,fr_speed_l,to_speed_l,dir_travel,
ST_Transform(geom,3068) as geom from t2019_kar_streets

select st_srid(geom),* from streets_reprojected
--4--
--Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
--Użyj następujących współrzędnych:
--X Y
--8.36093 49.03174
--8.39876 49.00644
--Przyjmij układ współrzędnych GPS.

create table input_points (
	id INT PRIMARY KEY,
	geom geometry
);

insert into input_points values(1,ST_GeomFromText('POINT(8.36093 49.03174)',4326));
insert into input_points values(2,ST_GeomFromText('POINT(8.39876 49.00644)',4326));

select * from input_points
delete from input_points;
drop table input_points;

--5--
--Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
--DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText().
alter table input_points
  alter column geom type geometry(POINT, 3068)
    using ST_Transform(geom,3068);

select st_AsText(geom),st_srid(geom) from input_points
--6--
--Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
--z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
--reprojekcji geometrii, aby była zgodna z resztą tabel.
select st_srid(geom) from t2019_kar_street_node
select * from input_points;

select s.* as dist from t2019_kar_street_node as s,
(select st_makeline(ip1.geom,ip2.geom) as line from input_points as ip1, input_points as ip2
				  where ip1.id = 1 and ip2.id =2) as t
where s.intersect = 'Y' and st_distance(st_transform(t.line,3857),st_transform(s.geom,3857)) <= 200;


--7--
--Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
--w odległości 300 m od parków (LAND_USE_A).
select count (*) from (
	select distinct tabA.* from t2019_kar_poi_table as tabA,
	t2019_kar_land_use_a as tabB
	where tabA.type = 'Sporting Goods Store'
	and tabB.type = 'Park (City/County)'
	and ST_Distance(st_transform(tabA.geom,3857), st_transform(tabB.geom,3857)) < 300
) as tmp



select * from t2019_kar_land_use_a
select * from t2019_kar_poi_table as bb where bb.type = 'Sporting Goods Store'
--8--
--Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
--znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’
select st_asText(geom),st_srid(geom), * from t2019_kar_railways
select st_asText(geom),st_srid(geom), * from t2019_kar_water_lines

Create table T2019_KAR_BRIDGES as
select distinct(st_intersection(tabA.geom, tabB.geom)) as geom from t2019_kar_railways as tabA,
t2019_kar_water_lines as tabB
WHERE ST_Intersects(tabA.geom, tabB.geom)
---distinct out moze nie potrzebny
