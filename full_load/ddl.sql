/*
dataset in the local repository was loaded to a staging area from whereit would be directly loaded to the bronze layer
This script shows how the database schemas  Bronze, silver and gold layers were created in snowflake using SQL.
Also SQL was used for the creation and as well the loading of parquet file into the stage area
*/
--to create  database and schema in snowflake
CREATE  OR REPLACE DATABASE full_load_NYC_TAXI;

CREATE OR REPLACE  SCHEMA bronze;

CREATE OR REPLACE  SCHEMA silver;

CREATE OR REPLACE SCHEMA gold;

USE SCHEMA bronze;


CREATE OR REPLACE FILE FORMAT parquet  --create file  format
    TYPE = PARQUET;


CREATE OR REPLACE STAGE full_load_dec_taxi -- Create an internal stage./* */
FILE_FORMAT = parquet;


list '@full_load_dec_taxi' --to access files in stage


 SELECT *                         --- Query the INFER_SCHEMA function.
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@full_load_dec_taxi'
      , FILE_FORMAT=>'parquet'
      )
    );

    ---create table with the inferred schema 
    CREATE OR REPLACE TABLE yellow_tripdate_2024
USING TEMPLATE (
  SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION => '@full_load_dec_taxi', 
      FILE_FORMAT => 'parquet'
    )
  )
      
  

