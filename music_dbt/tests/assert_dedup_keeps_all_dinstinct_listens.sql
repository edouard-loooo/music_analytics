with count_from_stg as (
    select count(distinct {{ dbt_utils.generate_surrogate_key(['user_name', 'listened_at', 'recording_msid']) }}) as count_stg 
    from {{ ref('stg_listens') }}
),

count_from_dedup as (
    select count(*) as count_dedup 
    from {{ ref('int_listens_deduplicated') }}
)

select 
    count_stg,
    count_dedup
from count_from_stg
cross join count_from_dedup
where count_stg != count_dedup