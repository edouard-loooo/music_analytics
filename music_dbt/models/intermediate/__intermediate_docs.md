{% docs artist_resolution_method %}

One of the following values: 

| method          | description                                            |
|-----------------|--------------------------------------------------------|
| musicbrainz     | mbid listenbrainz mapping (mbid_mapping.artists)       |
| lastfm          | mbid from additional_info.lastfm_artist_mbid, accepted only if exists in stg_artists  |
| name_imputation | mbid recovered through normalized name matching        |
| text_only       | unable to recover a mbid, name only will is used as key |

Recovery methods applied in this order, the first one to success is selected

{% enddocs %}


{% docs int_listen_artists %}

- Intermediate model to map artists mbids on listens, using different sources to recover the maximum possible. 
- artists with same names and 'text_only' recovery method are merged with same artist key
- Unable to recover featuring artists when appearing only on the track title

{% enddocs %}