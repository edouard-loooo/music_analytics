select
  count(*)                                   as lignes,              
  count(distinct requested_mbid)             as distinct_requested_mbid, 
  countif(canonical_mbid is distinct from requested_mbid)  as different_canonical_mbid,
  countif(release_date is not null)          as non_null_release_date,
  countif(release_group_first_release_year is not null)          as non_null_first_release_year,
  countif(language_code is not null)         as non_null_language_code,
  countif(disambiguation is not null)        as non_null_disambiguation
from {{ ref('stg_releases') }}