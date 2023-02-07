---ZAD1 --- ST_Intersects
CREATE TABLE schema_szeliga.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table schema_szeliga.intersects
add column rid SERIAL PRIMARY KEY;

--kregoslup kolekcji geomerii, gist oznacza generyczny strukture indeksu
CREATE INDEX idx_intersects_rast_gist ON schema_szeliga.intersects
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_szeliga'::name,
'intersects'::name,'rast'::name);

---ZAD2 --- ST_Clip
CREATE TABLE schema_szeliga.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

---ZAD3 --- ST_Union
CREATE TABLE schema_name.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

---TWORZENIE RASTROW Z WEKTOROW ---
---ZAD1 --- ST_AsRaster
CREATE TABLE schema_szeliga.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

select * from schema_szeliga.porto_parishes

---ZAD2 --- ST_Union
DROP TABLE schema_szeliga.porto_parishes;
CREATE TABLE schema_szeliga.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

---ZAD3 -- ST_Tile -- generowanie kafelków
DROP TABLE schema_szeliga.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_szeliga.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--- RASTRY NA WEKTORY ---
---ZAD1 --ST_Intersection
CREATE TABLE schema_szeliga.intersection AS
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

---ZAD2 -- ST_DumpAsPolygons (rastry -> wektor)
CREATE TABLE schema_szeliga.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

---geomval is a compound data type consisting of a geometry object referenced by the .geom field and val, a double precision value that represents the pixel value at a particular geometric location in a raster band.
---ANALIZA RASTRÓW ---
---ZAD1 -- ST_Band

CREATE TABLE schema_szeliga.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

---ZAD2 -- ST_Clip
CREATE TABLE schema_szeliga.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

---ZAD3 -- ST_Slope -- (ST_Slope(raster rast, integer nband=1, text pixeltype=32BF, text units=DEGREES, double precision scale=1.0, boolean interpolate_nodata=FALSE);)
CREATE TABLE schema_szeliga.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM schema_szeliga.paranhos_dem AS a;

---ZAD4 -- ST_Reclass
CREATE TABLE schema_szeliga.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM schema_szeliga.paranhos_slope AS a;

---ZAD5 -- ST_SummaryStats
SELECT st_summarystats(a.rast) AS stats
FROM schema_szeliga.paranhos_dem AS a;

---ZAD6 -- ST_SummaryStats + Union --zlozony typ danych - it is essentially just a list of field names and their data types
SELECT st_summarystats(ST_Union(a.rast))
FROM schema_szeliga.paranhos_dem AS a;

---ZAD7 -- ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM schema_szeliga.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

---ZAD8 -- ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

---ZAD9 -- ST_Value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

---ZAD10 -- ST_TPI
CREATE TABLE schema_szeliga.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON schema_szeliga.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_szeliga'::name,
'tpi30'::name,'rast'::name);

--- czas(1) vs czas(2) ---
--- 1.15 s  --  3 s


CREATE TABLE schema_szeliga.tpi30_2 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_2_rast_gist ON schema_szeliga.tpi30_2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_szeliga'::name,
'tpi30_2'::name,'rast'::name);

---ALGEBRA MAP---
---ZAD1 -- NDVI -- ST_MapAlgebra
CREATE TABLE schema_szeliga.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON schema_szeliga.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_szeliga'::name,
'porto_ndvi'::name,'rast'::name);

---ZAD2 -- NDVI -- return

create or replace function schema_szeliga.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--wywolanie funkcji
CREATE TABLE schema_szeliga.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'schema_szeliga.ndvi(double precision[],
integer[],text[])'::regprocedure,'32BF'::text)
AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON schema_szeliga.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_szeliga'::name,
'porto_ndvi2'::name,'rast'::name);

---EKSPORT DANYCH---
---ZAD1 -- ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM schema_szeliga.porto_ndvi;

---ZAD2 -- ST_AsGDALRaste
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM schema_szeliga.porto_ndvi;

---ZAD3 -- Duze obietky
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM schema_szeliga.porto_ndvi;


SELECT lo_export(loid, 'C:\Users\eweli\OneDrive\Pulpit\myraster.tiff') FROM tmp_out; --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.


SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost port=5432 dbname=postgis_raster user=postgres password=postgis schema=schema_szeliga table=porto_ndvi mode=2" porto_ndvi.tiff
---PUBLIKOWANIE---
---ZAD1 - WMS
MAP
NAME 'map'
SIZE 800 650
STATUS ON
EXTENT -58968 145487 30916 206234
UNITS METERS
WEB
METADATA
'wms_title' 'Terrain wms'
'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
'wms_enable_request' '*'
'wms_onlineresource'
'http://54.37.13.53/mapservices/srtm'
END
END
PROJECTION
'init=epsg:3763'
END
LAYER
NAME srtm
TYPE raster
STATUS OFF
DATA "PG:host=localhost port=5432 dbname='postgis_raster' user='postgres'
password='postgis' schema='rasters' table='dem' mode='2'" PROCESSING
"SCALE=AUTO"
PROCESSING "NODATA=-32767"
OFFSITE 0 0 0
METADATA
'wms_title' 'srtm'
END
END
END



---------------------------------------------------------------
CREATE TABLE public.mosaic (
    name character varying(254) COLLATE pg_catalog."default" NOT NULL,
    tiletable character varying(254) COLLATE pg_catalog."default" NOT NULL,
    minx double precision,
    miny double precision,
    maxx double precision,
    maxy double precision,
    resx double precision,
    resy double precision,
    CONSTRAINT mosaic_pkey PRIMARY KEY (name, tiletable)
);
insert into mosaic (name,tiletable) values ('mosaicpgraster','rasters.dem');