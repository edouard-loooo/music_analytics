with listens as (
    select * from {{ ref('stg_listens') }}
),

ranked as (
    select
        *,
        row_number() over (partition by listened_at, user_name, recording_msid
                           order by _loaded_at desc) as rn
    from listens
)

select 
    * except(rn),
    {{ dbt_utils.generate_surrogate_key(['user_name', 'listened_at', 'recording_msid']) }} as listen_id
from ranked
where rn = 1
