--ZAD 2 --
--.\raster2pgsql -s 4326 -I -N -32767 -C -M 'C:\Users\eweli\OneDrive\Pulpit\Studia\V semestr\Bazy_Danych_Przestrzennych_BezGita\Cwiczenia7\ras250_gb\data\ewe\*.tif' -F -t 100x100 rasters.uk_250k | .\psql -d raster -h localhost -U postgres -p 5432
--ZAD 3 --
--za pomocą QGis

select distinct filename from rasters.uk_250k
order by filename
select * from rasters.uk_250k

select *,st_astext(geom) from rasters.national_parks
--ZAD 6 --
CREATE TABLE rasters.uk_lake_district AS
SELECT ST_Clip(a.rast, b.geom, true)
FROM rasters.uk_250k AS a, rasters.national_parks AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.id=1;

--ZAD 7--
---NDWI= (Band 3 – Band 8)/(Band 3 + Band 8)

CREATE TABLE rasters.ndwi AS
WITH r1 AS (
SELECT ST_Clip(a.rast, ST_Transform(b.geom,32630),true) AS rast
FROM rasters.sentinel AS a, rasters.national_parks AS b
WHERE b.id=1 and a.filename = 'B03.tif'
), r2 AS (
SELECT ST_Clip(a.rast, ST_Transform(b.geom,32630),true) AS rast
FROM rasters.sentinel AS a, rasters.national_parks AS b
WHERE b.id=1 and a.filename = 'B08.tif'
)
SELECT
ST_MapAlgebra(
r1.rast,
r2.rast,
'([rast1.val] - [rast2.val]) / ([rast1.val] + [rast2.val])::float','32BF'
) AS rast
FROM r1,r2;