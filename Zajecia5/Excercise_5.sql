Create table obiekty (
Id INT PRIMARY KEY,
Nazwa VARCHAR(100),
Geom GEOMETRY
)

INSERT INTO obiekty VALUES(1,'obiekt1',ST_GeomFromText('COMPOUNDCURVE((0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1),CIRCULARSTRING(3 1, 4 2, 5 1),(5 1, 6 1))'))
INSERT INTO obiekty VALUES(2,'obiekt2',ST_GeomFromText('CURVEPOLYGON(COMPOUNDCURVE( (10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2),CIRCULARSTRING(14 2, 12 0, 10 2), (10 2, 10 6) ),
CIRCULARSTRING(11 2, 12 3, 13 2, 12 1, 11 2))'))
INSERT INTO obiekty VALUES(3,'obiekt3',ST_GeomFromText('COMPOUNDCURVE((7 15, 10 17),(10 17, 12 13),(12 13, 7 15))'))
INSERT INTO obiekty VALUES(4,'obiekt4',ST_GeomFromText('COMPOUNDCURVE((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)) '))
INSERT INTO obiekty VALUES(5,'obiekt5',ST_GeomFromText('MULTIPOINT Z((30 30 59),(38 32 234))'))
INSERT INTO obiekty VALUES(6,'obiekt6',ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2),POINT(4 2))'))


SELECT st_asText(geom),* FROM OBIEKTY

--ZAD1
--Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej
--obiekt 3 i 4.
SELECT ST_Area(ST_Buffer(ST_Shortestline(o1.geom,o2.geom),5)) FROM obiekty o1
join obiekty o2 on o1.id = 3 and o2.id=4

--ZAD2
--Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki.
UPDATE obiekty SET geom = ST_GeomFromText('POLYGON((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20))')
WHERE id=4

--ZAD3
--W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.

INSERT INTO obiekty(id,nazwa,geom)
SELECT 7,'obiekt7',St_Collect(o1.geom,o2.geom) FROM obiekty as o1
join obiekty as o2 on o1.id=3 and o2.id=4

--ZAD4
-- Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie
--zawierających łuków.

SELECT Sum(ST_Area(ST_Buffer(o.geom, 5))) FROM obiekty as o
WHERE st_hasArc(o.geom) = FALSE

