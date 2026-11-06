{{ config(
    materialized='incremental',
    unique_key=['user', 'tst'],
    incremental_strategy='merge',
    on_schema_change='sync_all_columns'
) }}

WITH source AS (

    SELECT
        user,
        acc,
        vac,
        lat,
        lon,
        alt,
        vel,
        tst,
        cog
    FROM {{ source('raw_data', 'user_locations') }}

    {% if is_incremental() %}

    WHERE tst >= (
        SELECT COALESCE(MAX(tst), 0) - 300
        FROM {{ this }}
    )

    {% endif %}

),

deduplicated_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY user, tst
            ORDER BY tst DESC
        ) AS rn

    FROM source

),

cleaned_data AS (

    SELECT
        user,
        acc,
        vac,
        lat,
        lon,
        alt,
        vel,
        tst,
        cog
    FROM deduplicated_data
    WHERE rn = 1
      AND acc < 100

),

deltas AS (

    SELECT
        *,
        TIMESTAMP_SECONDS(CAST(tst AS INT64)) AS date_time,

        LAG(lon) OVER (
            PARTITION BY user
            ORDER BY tst
        ) AS prev_lon,

        LAG(lat) OVER (
            PARTITION BY user
            ORDER BY tst
        ) AS prev_lat,

        LAG(tst) OVER (
            PARTITION BY user
            ORDER BY tst
        ) AS prev_tst


    FROM cleaned_data

)

SELECT
    user,
    acc,
    vac,
    lat,
    lon,
    alt,
    vel,
    tst,
    cog,
    date_time,
    prev_lon,
    prev_lat,
    prev_tst,
    CASE
        WHEN prev_tst IS NULL THEN NULL
        ELSE tst - prev_tst
    END AS time_delta,

    CASE
        WHEN prev_lat IS NULL OR prev_lon IS NULL THEN NULL

        ELSE ST_DISTANCE(
            ST_GEOGPOINT(lon, lat),
            ST_GEOGPOINT(prev_lon, prev_lat)
        )

    END AS distance

FROM deltas ORDER BY user DESC, tst DESC
