with listens as (
    select * from {{ ref('int_listens_deduplicated') }}
),

mb_artists as (
    select
        l.listen_id,
        artist_position,
        json_value(a.artist_mbid) as artist_mbid,
        json_value(a.artist_credit_name) as artist_credit_name,
        'musicbrainz' as artist_resolution_method
    from listens as l, unnest(json_query_array(l.artists)) as a with offset as artist_position
),

orphan_artists as (
    select
        *
    from listens as l 
    where not exists (
        select 1
        from unnest(json_query_array(l.artists)) as a
    )
),

orphans_resolved as (
    select 
        o.listen_id,
        0 as artist_position,
        coalesce(a.requested_mbid, a2.artist_mbid) as artist_mbid,
        submitted_artist_name as artist_credit_name,
        case 
            when a.requested_mbid is not null then 'lastfm'
            when a2.artist_mbid is not null then 'name_imputation'
            else 'text_only'
        end as artist_resolution_method
    from orphan_artists as o
    left join {{ ref('stg_artists') }} as a
        on o.lastfm_artist_mbid = a.requested_mbid
    left join {{ ref('int_artist_name_map') }} as a2
        on {{ normalize_artist_name('o.submitted_artist_name') }} = a2.normalized_artist_name
),

merged as (
    select
        *,
        coalesce(artist_mbid, concat('name:',{{ normalize_artist_name('artist_credit_name') }})) as artist_key
    from (
        select 
            listen_id,
            artist_position,
            artist_mbid,
            artist_credit_name,
            artist_resolution_method
        from mb_artists
        union all
        select 
            listen_id,
            artist_position,
            artist_mbid,
            artist_credit_name,
            artist_resolution_method
        from orphans_resolved
    ) as u
)


select * from merged 