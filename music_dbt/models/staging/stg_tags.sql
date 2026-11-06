with raw_source as (
    select * from {{ source('raw', 'artists_musicbrainz') }}
),

expanded as (

    select 

        concat(raw.requested_mbid, ' - ', json_value(tag.name)) as tag_id,
        raw.requested_mbid as artist_mbid,
        json_value(tag.name) as tag_name,
        cast(json_value(tag.count) as int64) as nb_vote,
        (
            select json_value(genre.id)                                 
            from unnest(json_query_array(payload.genres)) as genre
            where json_value(genre.name) = json_value(tag.name)                                        
        ) as genre_mbid,

    from raw_source as raw, unnest(json_query_array(payload.tags)) as tag
),

bucketed as (

    select 
        *,
        genre_mbid is not null as is_genre

    from expanded
)

select * from bucketed