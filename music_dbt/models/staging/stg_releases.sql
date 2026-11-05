with raw_source as (
    select * from {{ source('raw', 'releases_musicbrainz') }}
),

renamed as (

    select

        _fetched_at,
        requested_mbid,
        id as canonical_mbid,
        raw_source.name as release_name,

        JSON_VALUE(payload.country) as release_country_code,
        NULLIF(JSON_VALUE(payload.date), '') as release_date,
        NULLIF(JSON_VALUE(payload.disambiguation), '') as disambiguation,
        JSON_VALUE(payload.status) as release_status,

        JSON_VALUE(payload, '$."release-group".id') as release_group_mbid,
        JSON_VALUE(payload, '$."release-group".title') as release_group_name,
        NULLIF(JSON_VALUE(payload, '$."release-group"."first-release-date"'), '') as release_group_first_release_date,
        JSON_VALUE(payload, '$."release-group"."primary-type"') as release_group_primary_type,
        JSON_VALUE_ARRAY(payload, '$."release-group"."secondary-types"') as release_group_secondary_types,

        JSON_VALUE(payload, '$."text-representation"."language"') as language_code,
        
    from raw_source
),

derived as (

    select

        *,
        case 
            when STARTS_WITH(release_date, '????') then NULL
            else  CAST(SUBSTR(release_date, 1, 4) as int64) 
        end as release_year,

        case 
            when STARTS_WITH(release_group_first_release_date, '????') then NULL
            else  CAST(SUBSTR(release_group_first_release_date, 1, 4) as int64) 
        end as release_group_first_release_year,

    from renamed
)

select * from derived