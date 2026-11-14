with artists as (
    select * from {{ ref('snap_artists') }}
),

versioned_from_snapshot as (
    select
        * except (dbt_valid_from, dbt_valid_to, dbt_scd_id, dbt_updated_at, _fetched_at),
        requested_mbid as artist_key,
        dbt_valid_from as first_observed_at,
        case 
            when 
                row_number() over (partition by requested_mbid
                                order by dbt_valid_from) = 1 
            then timestamp '1900-01-01'
            else dbt_valid_from
        end as valid_from,
        dbt_valid_to as valid_to,
        (dbt_valid_to = timestamp '9999-12-31') as is_current,
        true as has_musicbrainz_metadata
    from artists
),

text_onlys as (
    select
        min(artist_credit_name) as artist_name,
        artist_key,
        timestamp '1900-01-01' as valid_from,
        timestamp '9999-12-31' as valid_to,
        true as is_current,
        false as has_musicbrainz_metadata
    from {{ ref('int_listen_artists')}}
    where artist_resolution_method = 'text_only'
    group by artist_key
),

merged as (
    select 
        *,
        {{ dbt_utils.generate_surrogate_key(['artist_key', 'valid_from']) }} as artist_version_key
    from (
        select * from versioned_from_snapshot
        full union all by name
        select * from text_onlys
    ) as u
)

select * from merged