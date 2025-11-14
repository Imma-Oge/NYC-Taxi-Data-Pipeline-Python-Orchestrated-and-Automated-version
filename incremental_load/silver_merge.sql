---------inserting records from bronze  to silverlayer
/*
This method uses both streams as metadata for tracking changes(insert) on the raw table 
and load the transformation to the silver layer)
*/



-----------------------------------------------------------------------------------------

 

 -------creating the transformed Table in the silver layer

 CREATE OR REPLACE TABLE silver.trans_nyc_taxi
(  

    vendor_id NUMBER(38,0),
    pickup_time timestamp,
	dropoff_time timestamp,
    months date,
    total_passengers NUMBER(38,0),
    trip_distance FLOAT,
    distance_group VARCHAR(50),
    ratecode_group VARCHAR(50),
    store_and_fwd_indication VARCHAR(50),
    taximeter_engaged_zone NUMBER(38,0),
    taximeter_disengaged_zone NUMBER(38,0),
    payment_type VARCHAR(50),
    fare_amount FLOAT,
    extra FLOAT,
    metered_rate_tax FLOAT,
    creditcard_tip_amount FLOAT,
    tolls_amount FLOAT,
	improvement_surcharge FLOAT, 
	total_amount_excluding_cash_tip FLOAT,
	congestion_surcharge FLOAT,
	LaGuardia_JFK_fee FLOAT,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP() 


----to create stored procedure 
    CREATE OR REPLACE PROCEDURE merge_nyc_taxi_data()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    var sql_command = `
    	
    
----to load delta files from stream         
   MERGE INTO silver.trans_nyc_taxi AS T
USING (
    SELECT 
        VendorID AS vendor_id,
        TO_TIMESTAMP(tpep_pickup_datetime::VARCHAR) AS pickup_time,
        TO_TIMESTAMP(tpep_dropoff_datetime::VARCHAR) AS dropoff_time,
        DATE_TRUNC('month', TO_TIMESTAMP(tpep_pickup_datetime::VARCHAR)) AS months,
        passenger_count AS total_passengers,
        trip_distance,
        CASE
            WHEN trip_distance BETWEEN 0.01 AND 79721.73 THEN 'Extra short'
            WHEN trip_distance BETWEEN 80721.74 AND 159443.46 THEN 'Short'
            WHEN trip_distance BETWEEN 159443.47 AND 239165.19 THEN 'Medium'
            WHEN trip_distance BETWEEN 239165.20 AND 318886.92 THEN 'Long'
            WHEN trip_distance BETWEEN 318886.93 AND 398608.62 THEN 'Extreme long'
            ELSE 'None'
        END AS distance_group,
        CASE RatecodeID
            WHEN 1 THEN 'Standard rate'
            WHEN 2 THEN 'JFK'
            WHEN 3 THEN 'Newark'
            WHEN 4 THEN 'Nassau or Westchester'
            WHEN 5 THEN 'Negotiated fare'
            WHEN 6 THEN 'Group ride'
            WHEN 99 THEN NULL
            ELSE NULL
        END AS ratecode_group,
        CASE 
            WHEN store_and_fwd_flag = 'N' THEN 'No'
            WHEN store_and_fwd_flag = 'Y' THEN 'Yes'
            ELSE 'Not indicated'
        END AS store_and_fwd_indication,
        PULocationID AS taximeter_engaged_zone,
        DOLocationID AS taximeter_disengaged_zone,
        CASE payment_type
            WHEN 0 THEN 'Flex Fare trip'
            WHEN 1 THEN 'Credit card'
            WHEN 2 THEN 'Cash'
            WHEN 3 THEN 'No charge'
            WHEN 4 THEN 'Dispute'
            WHEN 5 THEN 'Unknown'
            ELSE 'Voided trip'
        END AS payment_type,
        fare_amount,
        REPLACE(extra, '-', '') AS extra,
        mta_tax AS metered_rate_tax,
        tip_amount AS creditcard_tip_amount,
        tolls_amount,
        improvement_surcharge,
        total_amount AS total_amount_excluding_cash_tip,
        congestion_surcharge,
        Airport_fee AS LaGuardia_JFK_fee,
        CURRENT_TIMESTAMP AS last_updated_at
    FROM raw_stream
) AS S
ON T.vendor_id = S.vendor_id
   AND T.pickup_time = S.pickup_time
   AND T.dropoff_time = S.dropoff_time

WHEN MATCHED THEN
    UPDATE SET
        T.total_passengers = S.total_passengers,
        T.trip_distance = S.trip_distance,
        T.distance_group = S.distance_group,
        T.ratecode_group = S.ratecode_group,
        T.store_and_fwd_indication = S.store_and_fwd_indication,
        T.taximeter_engaged_zone = S.taximeter_engaged_zone,
        T.taximeter_disengaged_zone = S.taximeter_disengaged_zone,
        T.payment_type = S.payment_type,
        T.fare_amount = S.fare_amount,
        T.extra = S.extra,
        T.metered_rate_tax = S.metered_rate_tax,
        T.creditcard_tip_amount = S.creditcard_tip_amount,
        T.tolls_amount = S.tolls_amount,
        T.improvement_surcharge = S.improvement_surcharge,
        T.total_amount_excluding_cash_tip = S.total_amount_excluding_cash_tip,
        T.congestion_surcharge = S.congestion_surcharge,
        T.LaGuardia_JFK_fee = S.LaGuardia_JFK_fee,
        T.last_updated_at = S.last_updated_at

WHEN NOT MATCHED  THEN
    INSERT (
        vendor_id, pickup_time, dropoff_time, months, total_passengers,
        trip_distance, distance_group, ratecode_group, store_and_fwd_indication,
        taximeter_engaged_zone, taximeter_disengaged_zone, payment_type, 
        fare_amount, extra, metered_rate_tax, creditcard_tip_amount,
        tolls_amount, improvement_surcharge, total_amount_excluding_cash_tip,
        congestion_surcharge, LaGuardia_JFK_fee, last_updated_at
    )
    VALUES (
        S.vendor_id, S.pickup_time, S.dropoff_time, S.months, S.total_passengers,
        S.trip_distance, S.distance_group, S.ratecode_group, S.store_and_fwd_indication,
        S.taximeter_engaged_zone, S.taximeter_disengaged_zone, S.payment_type, 
        S.fare_amount, S.extra, S.metered_rate_tax, S.creditcard_tip_amount,
        S.tolls_amount, S.improvement_surcharge, S.total_amount_excluding_cash_tip,
        S.congestion_surcharge, S.LaGuardia_JFK_fee, S.last_updated_at
    );

      `)
       
    
    snowflake.execute({sqlText: sql_command});
    return "Merge operation executed successfully.";
$$;


-----------------run the procedure

CALL merge_nyc_taxi_data();

   
   
    







