
  --------full load strategy for all NYC Taxi data
/*
This method loads all 2024 yellow_nyc_taxi parquet files from the named stage 
to table already created at once using the copy into command 

note: All  ETL processes commands and codes were written using  Snowflake warehouse
*/

--loading data from stage 

 COPY INTO yellow_tripdate_2024
    FROM @full_load_dec_taxi
    FILE_FORMAT = parquet
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

SELECT * FROM yellow_tripdate_2024
