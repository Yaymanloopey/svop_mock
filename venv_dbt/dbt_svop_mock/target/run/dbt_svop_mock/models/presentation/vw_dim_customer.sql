

  create or replace view `peters-datasets`.`dbt_svop_mock_schema_presentation`.`vw_dim_customer`
  OPTIONS()
  as 
/*
    This view is used to create the dim_customer table
    For each unique customer_id, this object will store name, first_seen_date and last_seen_date and their latest activity state location
*/
with cte_customer as (
    select
        customer_id
        , min(event_date) as first_seen_date
        , max(event_date) as last_seen_date 
        , null customer_first_name
        , null customer_last_name
        , to_hex(md5(concat(
            COALESCE(CAST(CTE.customer_id AS STRING),''),'||'
        ))) sys_record_checksum
        , current_datetime('Australia/Sydney') sys_insert_datetime
    from `peters-datasets`.`dbt_svop_mock_schema_landing`.`policy_events` cte
    group by 1,sys_record_checksum, sys_insert_datetime
)
/*
    FOR EACH CUSTOMER, TAKE THE LATEST STATE THAT THEY CARRIED OUT ACTIVITY
*/
, cte_customer_latest_location as(
    select
        *
    from(
        select  
            customer_id
            , state last_seen_state
            , row_number() over (partition by customer_id order by event_date desc) as instance
        from `peters-datasets`.`dbt_svop_mock_schema_landing`.`policy_events`
    )
    where instance = 1 
)

select
    -- customer_surkey.dim_customer_sk
    cc.customer_id
    , cc.customer_first_name
    , cc.customer_last_name
    , cc.first_seen_date
    , cc.last_seen_date
    , cll.last_seen_state
    , cc.sys_record_checksum
    , cc.sys_insert_datetime
from cte_customer cc
left join cte_customer_latest_location  cll
    on cc.customer_id = cll.customer_id;

