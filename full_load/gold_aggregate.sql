-----aggregating and loading summaized result to GOLD layer 

select * from silver.transf_yellow_tripdate_2024


/*----------Gold layer----------------
 In this aggregated layer, data aggregations and key metrics such as total_tip, 
  total_amount and total_passengers were tracked. according to segemnts such as payment type or various distance groups
  the result of this aggregation was persisted as a view in the gold layer
*/
  ---aggregated result loading into gold as view
 CREATE OR REPLACE VIEW gold.aggregate_result AS
 (
select 
    left(date_trunc(month,PICKUP_TIME),10) AS monthly_pickup,
    left(date_trunc(month,DROPOFF_TIME),10) AS monthly_dropoff,
    DISTANCE_GROUP,
    STORE_AND_FWD_INDICATION,
    payment_type,
    COUNT(total_passengers) AS total_no_of_passengers, 
    SUM(tolls_amount) as Total_tolls,
    SUM(total_amount_excluding_cash_tip) AS total_amount,
    SUM(creditcard_tip_amount) AS Total_creditcard_tip
    
from silver.transf_yellow_tripdate_2024
group by distance_group, store_and_fwd_indication,payment_type,
    left(date_trunc(month,PICKUP_TIME),10),left(date_trunc(month,DROPOFF_TIME),10)
    )
