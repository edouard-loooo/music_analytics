select
  count(*)                                   as lignes,              
  count(distinct requested_mbid)             as distinct_requested_mbid, 
  countif(artist_type is not null)           as non_null_types,       
  countif(country_code is not null)          as non_null_country, 
  countif(life_span_begin is not null)  as non_null_begin_string,          
  countif(life_span_begin_year is not null)  as non_null_begin_year,  
  countif(disambiguation is not null)    as non_null_disambiguation     
from {{ ref('stg_artists') }}