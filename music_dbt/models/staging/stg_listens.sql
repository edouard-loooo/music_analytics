with raw_source as (
    select * from {{ source('raw', 'listens_personal') }}
),

renamed as (

    select

        _loaded_at,
        listened_at,
        TIMESTAMP_SECONDS(CAST(JSON_VALUE(payload.inserted_at) as int64)) as inserted_at,

        user_name,
        recording_msid,
        source,

        JSON_VALUE(payload.track_metadata.artist_name) as submitted_artist_name,
        JSON_VALUE(payload.track_metadata.release_name) as submitted_release_name,
        JSON_VALUE(payload.track_metadata.track_name) as submitted_track_name,

        JSON_VALUE(payload.track_metadata.mbid_mapping.recording_mbid) as recording_mbid,
        JSON_VALUE(payload.track_metadata.mbid_mapping.release_mbid) as release_mbid,
        JSON_VALUE(payload.track_metadata.mbid_mapping.recording_name) as recording_name,

        JSON_VALUE_ARRAY(payload.track_metadata.mbid_mapping.artist_mbids) as artist_mbids,

        payload.track_metadata.mbid_mapping.artists as artists,

        CAST(JSON_VALUE(payload.track_metadata.mbid_mapping.caa_id) as int64) as caa_id,
        JSON_VALUE(payload.track_metadata.mbid_mapping.caa_release_mbid) as caa_release_mbid,

        JSON_VALUE(payload.track_metadata.additional_info.lastfm_artist_mbid) as lastfm_artist_mbid,

        JSON_VALUE(payload.track_metadata.additional_info.submission_client) as submission_client

    from raw_source
)

select * from renamed
 
