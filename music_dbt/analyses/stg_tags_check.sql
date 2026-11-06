select
  count(*)                     as lignes,              
  count(distinct artist_mbid)  as distinct_artists, 
  count(distinct tag_name)     as distinct_tags,    
  countif(is_genre)            as true_is_genre,
  count(distinct genre_mbid)   as distinct_genres  
from {{ ref('stg_tags') }}