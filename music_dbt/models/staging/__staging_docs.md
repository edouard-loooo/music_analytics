{% docs stg_listens %}

- staging of listens table
- 1 row per listens, including doubles

- msid = MessyBrainz ID = 1 id per unique string recieved by ListenBrainz
- mbid = MusicBrainz ID = Id of the registered data in MusicBrainz, can be missing

- artists_mbids is [] when artist not recognized and not null 
- lastfm_artist_mbid is a second mbid source, 95% matching with original mbid, can use as fallback on some non recognized artists
- inserted_at is the date of registration in ListenBrainz, not listen date 

{% enddocs %}

{% docs stg_releases %}



{% enddocs %}

{% docs stg_artists %}

- staging of artists table
- 1 row per requested artist mbids

- canonical mbids are recieved ids from the api after potential 301 redirect, can have doubles
- dates may be incomplete, year is derived when available but some rows only have month and/or day


{% enddocs %}