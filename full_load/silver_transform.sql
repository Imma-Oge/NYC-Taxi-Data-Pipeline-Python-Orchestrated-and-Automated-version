
 ----LOADING DAT INTO SILVER LAYER FULL LOAD STRATEY

 INSERT INTO silver.transf_yellow_tripdate_2024
 (
  SELECT 
        "VendorID" as vendor_id,
        TO_TIMESTAMP("tpep_pickup_datetime"::VARCHAR) as pickup_time,
        TO_TIMESTAMP("tpep_dropoff_datetime"::VARCHAR) as dropoff_time,
        "passenger_count" as total_passengers,
        "trip_distance",
       CASE
            WHEN "trip_distance"  BETWEEN  0.01 AND 79721.73  THEN  'Extra shorT' 
            WHEN "trip_distance"  BETWEEN  80721.74 AND 159443.46  THEN 'Short' 
            WHEN "trip_distance"  BETWEEN  159443.47 AND 239165.19 THEN 'Medium' 
            WHEN "trip_distance"  BETWEEN  239165.20 AND 318886.92 THEN 'Long' 
            WHEN "trip_distance"  BETWEEN  318886.93 AND 398608.62 THEN 'Exteme long' 
    ELSE 'None'
    END AS distance_group,
         CASE    "RatecodeID"
        WHEN  1 THEN 'Standard rate'
        WHEN  2 THEN 'JFK'
        WHEN  3 THEN 'Newark'
        WHEN  4 THEN 'Nassau or Westchester'
        WHEN  5 THEN 'Negotiated fare'
        WHEN  6 THEN 'Group ride'
        WHEN  99 THEN NulL
    ELSE null
    END AS ratecode_group,
     CASE 
        WHEN "store_and_fwd_flag" ='N' THEN 'No'
        WHEN "store_and_fwd_flag" ='Y' THEN'Yes'
    ELSE 'Not indicated'
    END AS store_and_fwd_indication,
    "PULocationID" AS taximeter_engaged_zone,
    "DOLocationID" AS taximeter_disengaged_zone,
     CASE "payment_type"
        WHEN 0 THEN 'Flex Fare trip'
        WHEN 1 THEN 'Credit card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
     ELSE 'Voided trip'
    END AS "payment_type", 
    "fare_amount",
    REPLACE("extra",'-',NULL) as extra, 
    "mta_tax" AS metered_rate_tax,
    REPLACE("tip_amount",'-',0) AS creditcard_tip_amount,
    REPLACE("tolls_amount",'-',0) AS tolls_amount,
    "improvement_surcharge",
    REPLACE("total_amount",'-',0) AS total_amount_excluding_cash_tip,
    "congestion_surcharge",
    REPLACE("Airport_fee",'-',0) AS LaGuardia_JFK_fee, 

FROM yellow_tripdate_2024 
WHERE "VendorID" IN (1,2,6,7) AND "payment_type" IN(0,1,2,3,4,5,6)

 )
SELECT * FROM SILVER.TRANSF_YELLOW_TRIPDATE_2024
