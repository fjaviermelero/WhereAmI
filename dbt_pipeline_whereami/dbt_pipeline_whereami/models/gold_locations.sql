{{ config(
    materialized='table',
    unique_key=['city', 'user'],
) }}

WITH locations AS (
    SELECT
        *,
        ST_GEOGPOINT(lon, lat) AS point
    FROM {{ ref('silver_whereami') }}
    WHERE lat IS NOT NULL
      AND lon IS NOT NULL
),

localities AS (
    SELECT
        id,
        names.primary AS city,
        geometry
    FROM `bigquery-public-data.overture_maps.division_area`
    WHERE country = 'ES'
      AND subtype = 'locality'
      AND is_land = TRUE
),

city_hours AS (
    SELECT
        CASE 
            WHEN SUM(l.time_delta)/3600 >3 THEN loc.city
            ELSE "Others"
        END AS city,
        l.user,
        SUM(l.time_delta)/3600 as spent_hours,
    FROM locations l
    LEFT JOIN localities loc
        ON ST_CONTAINS(loc.geometry, l.point)

    GROUP BY loc.city, l.user
)

SELECT 
    user,
    city,
    SUM(spent_hours) AS total_hours
FROM city_hours
GROUP BY user, city
ORDER BY total_hours DESC