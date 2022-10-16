-- Database: mapa

-- DROP DATABASE IF EXISTS mapa;

CREATE DATABASE mapa
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
	
CREATE EXTENSION postgis;

Create table budynki(
	id INT PRIMARY KEY,
	geometria GEOMETRY,
	nazwa VARCHAR(50),
	wysokosc DECIMAL
);

CREATE TABLE drogi(
	id INT PRIMARY KEY,
	geometria GEOMETRY,
	nazwa VARCHAR(50)
);

CREATE TABLE pktinfo(
	id INT PRIMARY KEY ,
	geometria GEOMETRY,
	nazwa VARCHAR(50),
	liczprac INT
);

INSERT INTO drogi VALUES (1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)',0), 'RoadX');
INSERT INTO drogi VALUES (2, ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)',0), 'RoadY');
select * from PKTINFO

INSERT INTO pktinfo VALUES (1, ST_GeomFromText('POINT(1 3.5)',0),'G',5);
INSERT INTO pktinfo VALUES (2, ST_GeomFromText('POINT(5.5 1.5)',0),'H',1);
INSERT INTO pktinfo VALUES (3, ST_GeomFromText('POINT(9.5 6)',0),'I',8);
INSERT INTO pktinfo VALUES (4, ST_GeomFromText('POINT(6.5 6)',0),'J',2);
INSERT INTO pktinfo VALUES (5, ST_GeomFromText('POINT(6 9.5)',0),'K',10);

INSERT INTO budynki VALUES (1, ST_GeomFromText('POLYGON((3 6, 3 8, 5 8, 5 6,3 6))',0),'BuildingC', 12.5);
INSERT INTO budynki VALUES (2, ST_GeomFromText('POLYGON((4 5, 4 7, 6 7, 6 5,4 5))',0),'BuildingB', 8.25);
INSERT INTO budynki VALUES (3, ST_GeomFromText('POLYGON((9 8, 9 9, 10 9, 10 8,9 8))',0),'BuildingD', 20);
INSERT INTO budynki VALUES (4, ST_GeomFromText('POLYGON((1 1, 1 2, 2 2, 2 1,1 1))',0),'BuildingF', 10.5);
INSERT INTO budynki VALUES (5, ST_GeomFromText('POLYGON((8 1.5, 8 4, 10.5 4, 10.5 1.5,8 1.5))',0),'BuildingA', 12);
SELECT * FROM BUDYNKI

####1###
SELECT sum(ST_Length(geometria)) as dlugosc_drog from drogi

###2###
SELECT ST_AsText(geometria) as WKT, ST_Area(geometria) as powierzchnia, ST_Perimeter(geometria) as obwod from budynki where nazwa = 'BuildingA'

###3###
SELECT nazwa, ST_Area(geometria) from budynki ORDER BY nazwa

###4###
SELECT nazwa, ST_Perimeter(geometria) AS obwod from budynki
ORDER BY ST_Area(geometria) DESC LIMIT 2

###5###
 SELECT ST_Distance(b.geometria, p.geometria) as najkrotsza_odleglosc from budynki as b
 join pktinfo as p on b.nazwa = 'BuildingC' and p.nazwa = 'G'
 
 SELECT ST_Distance(b.geometria, p.geometria) as najkrotsza_odleglosc from budynki as b
 cross join pktinfo as p where b.nazwa = 'BuildingC' and p.nazwa = 'G'

###6###
SELECT ST_Area(ST_Difference(b1.geometria,ST_Buffer(b2.geometria,0.5))) from budynki as b1
join budynki as b2 on b1.nazwa = 'BuildingC' and b2.nazwa = 'BuildingB'

###7##
SELECT * FROM budynki where ST_Y(ST_Centroid(geometria)) > 4.5 

###8###
SELECT ST_Area(ST_SymDifference(geometria, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))',0))) From budynki
where nazwa = 'BuildingC'



