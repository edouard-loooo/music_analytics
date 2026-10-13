select
  count(*)                                   as lignes,              
  countif(recording_mbid is not null)        as avec_recording_mbid, 
  countif(array_length(artist_mbids) > 0)    as avec_artistes,       
  countif(lastfm_artist_mbid is not null)    as avec_lastfm_artiste, 
  countif(caa_id is not null)                as avec_pochette       
from {{ ref('stg_listens') }}