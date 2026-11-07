with listens as (
    select * from {{ ref('int_listens_deduplicated') }}
),

normalized as (

    select
        {{ normalize_artist_name('json_value(a.artist_credit_name)') }} as normalized_artist_name,
        json_value(a.artist_mbid) as artist_mbid,
    from listens as l, unnest(json_query_array(l.artists)) as a

),

shared as (

    select
        normalized_artist_name,
        artist_mbid,
        count(*) / sum(count(*)) over (partition by normalized_artist_name) as share,
        count(*) as supporting_credits
    from normalized
    group by normalized_artist_name, artist_mbid

),

mapped as (

    select
        normalized_artist_name,
        artist_mbid,
        supporting_credits
    from shared
    qualify row_number() over (partition by normalized_artist_name 
                                   order by share desc, artist_mbid) = 1 and share >= {{ var('name_imputation_min_share') }}
)

select * from mapped