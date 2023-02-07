---4---
--Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
--położonych w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające to
--kryterium zapisz do osobnej tabeli tableB.
CREATE TABLE tableB AS
SELECT po.* FROM popp AS po
CROSS JOIN majrivers AS r WHERE po.f_codedesc = 'Building'
AND ST_Distance(po.geom,r.geom)<1000

SELECT COUNT(*) FROM TABLEB
---5---
--Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
--geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

CREATE TABLE airportsNew AS
SELECT name, geom, elev FROM airports

SELECT * FROM airports
--a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.
select st_astext(geom) from airportsnew

SELECT *, ST_asText(geom) FROM airportsNew as ar
ORDER BY st_y(geom) DESC LIMIT 1;

SELECT *, ST_asText(geom) FROM airportsNew as ar
ORDER BY st_y(geom) LIMIT 1
--b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
--środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.
--Wysokość n.p.m. przyjmij dowolną.
--Uwaga: geodezyjny układ współrzędnych prostokątnych płaskich (x – oś pionowa, y – oś pozioma)

INSERT INTO airportsNew(name,geom,elev)
SELECT 'airportB',ST_Centroid(ST_MakeLine(ar.geom,ar2.geom) ),547
from airportsNew as ar
JOIN airportsNew as ar2 on st_y(ar.geom) in (select max(st_y(geom)) from airportsNew)
and st_y(ar2.geom) in (select min(st_y(geom)) from airportsNew)

select count(*) from airportsNew
select * from airportsNew  where name = 'airportB'
select st_astext(geom) from airportsNew where name = 'airportB'
select st_srid(geom) from airportsNew where name = 'airportB'
delete from airportsnew where name = 'airportB'
COMMIT

---6---
--Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
--linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

select st_area(st_buffer(st_shortestline(l.geom, ar.geom),1000)) from airports as ar
join lakes as l on l.names = 'Iliamna Lake' and ar.name = 'AMBLER'

---7---
--Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
--poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps)
select * from swamp
select * from tundra
select * from trees
select distinct vegdesc from trees

select sum(st_area(st_intersection(tu.geom,tr.geom))),tr.vegdesc from trees as tr
cross join (select geom from tundra union select geom from swamp) as tu
group by tr.vegdesc


