{{ config(
    materialized='incremental',
    unique_key=['dates', 'vehicle'],
    incremental_strategy='merge',
) }}

WITH distances_datetimes AS (
    SELECT 
        distance,
        date_time,
    CASE 
        WHEN vel > 8 THEN 'car'
        ELSE 'Others'
    END AS vehicle
    FROM  {{ ref('silver_whereami') }}

    {% if is_incremental() %}
        WHERE DATE(date_time) >= DATE_SUB(
        CURRENT_DATE(),
        INTERVAL 2 DAY
        )
    {% endif %}

)

SELECT 

  DATE(date_time) AS dates,
  vehicle,
  SUM(distance) AS distances,

FROM distances_datetimes

GROUP BY DATE(date_time), vehicle
