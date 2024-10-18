
DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist 				VARCHAR(255),
    track 				VARCHAR(255),
    album 				VARCHAR(255),
    album_type 			VARCHAR(50),
    danceability 		FLOAT,
    energy 				FLOAT,
    loudness 			FLOAT,
    speechiness 		FLOAT,
    acousticness 		FLOAT,
    instrumentalness 	FLOAT,
    liveness 			FLOAT,
    valence		 		FLOAT,
    tempo 				FLOAT,
    duration_min 		FLOAT,
    title 				VARCHAR(255),
    channel 			VARCHAR(255),
    views 				FLOAT,
    likes 				BIGINT,
    comments 			BIGINT,
    licensed 			BOOLEAN,
    official_video 		BOOLEAN,
    stream 				BIGINT,
    energy_liveness 	FLOAT,
    most_played_on 		VARCHAR(50)
);

SELECT * from spotify;

-------- CHECK DATA INTEGERTY -----------
SELECT DISTINCT(artist)  FROM spotify;
SELECT MAX(duration_min) FROM spotify;		----- longest song is 77.9 minute 
SELECT MIN(duration_min) FROM spotify;     ----- ** some song have 0 mintue 
SELECT DISTINCT(channel) FROM spotify;
SELECT * FROM spotify WHERE title IS NULL
------ clean out the data ----- 
SELECT * FROM spotify
WHERE duration_min =0 ;     

DELETE FROM spotify
WHERE duration_min =0;




-------- Create tables -----------
DROP TABLE IF EXISTS artists;
CREATE TABLE artists (
    artist_id        SERIAL PRIMARY KEY,
    artist_name      VARCHAR(255) UNIQUE
);

DROP TABLE IF EXISTS albums;
CREATE TABLE albums (
    album_id         SERIAL PRIMARY KEY,
    artist_id        INT REFERENCES artists(artist_id),
    album_name       VARCHAR(255),
    album_type       VARCHAR(50),
    release_date     DATE
);

DROP TABLE IF EXISTS tracks;
CREATE TABLE tracks (
    track_id         SERIAL PRIMARY KEY,
    album_id         INT REFERENCES albums(album_id),
    track_name       VARCHAR(255),
    danceability     FLOAT,
    energy           FLOAT,
    loudness         FLOAT,
    speechiness      FLOAT,
    acousticness     FLOAT,
    instrumentalness FLOAT,
    liveness         FLOAT,
    valence          FLOAT,
    tempo            FLOAT,
    duration_min     FLOAT
);

DROP TABLE IF EXISTS platforms;
CREATE TABLE platforms (
    platform_id      SERIAL PRIMARY KEY,
    platform_name    VARCHAR(50) UNIQUE
);

DROP TABLE IF EXISTS streaming_data;
CREATE TABLE streaming_data (
    stream_id        SERIAL PRIMARY KEY,
    track_id         INT REFERENCES tracks(track_id),
    platform_id      INT REFERENCES platforms(platform_id),
    views            FLOAT,
    likes            BIGINT,
    comments         BIGINT,
    licensed         BOOLEAN,
    official_video   BOOLEAN,
    stream           BIGINT
);


--------- DATA ETL --------------
INSERT INTO artists (artist_name)
SELECT DISTINCT artist
FROM spotify;

INSERT INTO albums (
artist_id,
album_name,
album_type)
SELECT a.artist_id, s.album, s.album_type
FROM spotify s
JOIN artists a ON s.artist = a.artist_name;


INSERT INTO tracks(
	album_id,
	track_name,
	danceability,
	energy,
	loudness,
	speechiness,
	acousticness,
	instrumentalness,
	liveness,
	valence,
	tempo,
	duration_min
)
SELECT 
	al.album_id, 
	s.track, 
	s.danceability, 
	s.energy, 
	s.loudness, 
	s.speechiness,
	s.acousticness,
	s.instrumentalness,
	s.liveness,
	s.valence,
	s.tempo,
	s.duration_min
FROM spotify s
	JOIN albums al ON s.album = al.album_name;



INSERT INTO platforms(platform_name)
SELECT 	DISTINCT(most_played_on)
FROM spotify ;


INSERT INTO streaming_data (
    track_id,
    platform_id,
    views,
    likes,
    comments,
    licensed,
    official_video,
    stream)
SELECT 
t.track_id,
    p.platform_id,
    s.views,
    s.likes,
    s.comments,
    s.licensed,
    s.official_video,
    s.stream
FROM
	spotify s JOIN tracks t ON s.track = t.track_name
			  JOIN platforms p ON s.most_played_on = p.platform_name;


