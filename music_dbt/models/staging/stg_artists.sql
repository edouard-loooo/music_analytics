with raw_source as (
    select * from {{ source('raw', 'artists_musicbrainz') }}
),

renamed as (

    select 

        _fetched_at,
        requested_mbid,
        id as canonical_mbid,
        raw_source.name as artist_name,

        JSON_VALUE(payload.area.name) as area_name,
        JSON_VALUE(payload.country) as country_code,
        JSON_VALUE(payload, '$."begin-area".name') as begin_area_name,

        JSON_VALUE(payload.gender) as gender,

        NULLIF(JSON_VALUE(payload, '$."life-span".begin'), '') as life_span_begin,
        NULLIF(JSON_VALUE(payload, '$."life-span".end'), '') as life_span_end,
        CAST(JSON_VALUE(payload, '$."life-span".ended') as boolean) as life_span_ended,

        NULLIF(JSON_VALUE(payload.disambiguation), '') as disambiguation,

        JSON_VALUE(payload, '$."sort-name"') as sort_name,
        JSON_VALUE(payload.type) as artist_type,
    
    from raw_source

),

derived as (

    select 

        *,
        case 
            when STARTS_WITH(life_span_begin, '????') then NULL
            else  CAST(SUBSTR(life_span_begin, 1, 4) as int64) 
        end as life_span_begin_year,
       

        case 
            when STARTS_WITH(life_span_end, '????') then NULL
            else  CAST(SUBSTR(life_span_end, 1, 4) as int64) 
        end as life_span_end_year,

    from renamed
)

select * from derived

