CREATE OR REPLACE DATABASE incremental_nyc_2024

USE DATABASE incremental_nyc_2024

CREATE OR REPLACE SCHEMA bronze;

CREATE OR REPLACE SCHEMA silver;

CEATE OR REPLACE SCHEMA gold;

USE SCHEMA  bronze

--to create a parquet file format 
CREATE OR REPLACE FILE FORMAT parquett
    TYPE = PARQUET;

    --to create an internal stage for loading the parquet files
CREATE OR REPLACE STAGE inc_load_dec_taxi
FILE_FORMAT = parquett;

---understanding stage construct using the infer schema 
list '@inc_load_dec_taxi'

-- Query the INFER_SCHEMA function.
 SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=> '@inc_load_dec_taxi', 
       FILE_FORMAT=>'parquett'
      )
    );

    ------creating the raw table 

CREATE OR REPLACE TABLE bronze.raw_nyc_taxi 
(  

              VendorID integer,
              tpep_pickup_datetime TIMESTAMP,
              tpep_dropoff_datetime TIMESTAMP,
              passenger_count INTEGER,
              trip_distance FLOAT,
              RatecodeID INTEGER,
              store_and_fwd_flag VARCHAR(50),
              PULocationID INTEGER,
              DOLocationID INTEGER,
              payment_type INTEGER,
              fare_amount FLOAT,
              extra FLOAT,
              mta_tax FLOAT,
              tip_amount FLOAT,
              tolls_amount FLOAT,
              improvement_surcharge FLOAT,
              total_amount FLOAT,
              congestion_surcharge FLOAT,
              Airport_fee FLOAT,
              uploaded_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP() 
    	
	
);
---creating stream to track changes(insert) in the raw table

CREATE OR REPLACE STREAM raw_stream ON TABLE bronze.raw_nyc_taxi

-------copy into table from stage with minimal transformation
COPY INTO bronze.raw_nyc_taxi
FROM (
    SELECT  
              
              $1:VendorID::integer,
              to_timestamp($1:tpep_pickup_datetime::string),
              to_timestamp($1:tpep_dropoff_datetime::string),
              $1:passenger_count::INTEGER,
              $1:trip_distance::FLOAT,
              $1:RatecodeID::INTEGER,
              $1:store_and_fwd_flag::VARCHAR(50),
              $1:PULocationID::INTEGER,
              $1:DOLocationID::INTEGER,
              $1:payment_type::INTEGER,
              $1:fare_amount::FLOAT,
              $1:extra::FLOAT,
              $1:mta_tax::FLOAT,
              $1:tip_amount::FLOAT,
              $1:tolls_amount::FLOAT,
              $1:improvement_surcharge::FLOAT,
              $1:total_amount::FLOAT,
              $1:congestion_surcharge::FLOAT,
              $1:Airport_fee::FLOAT,
              current_date AS last_updated_at           
     FROM @inc_load_dec_taxi
      );
     

     SELECT * FROM   bronze.raw_nyc_taxi 
     
     SELECT * FROM raw_stream


