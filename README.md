# Spotify SQL Project and Query Optimization 

![Spotify Logo](https://github.com/newgjkk/Spotify_SQL_project/blob/main/spotify_logo.jpg)

## Overview
This project involves analyzing a Spotify dataset with various attributes about tracks, albums, and artists using **SQL**. It covers an end-to-end process of normalizing a denormalized dataset, performing SQL queries of varying complexity, and optimizing query performance. The primary goals of the project is to generate valuable insights from the dataset.

## Project Structure
![ERD](https://github.com/newgjkk/Spotify_SQL_project/blob/main/spotify_pic.JPG)

### 1. Database Setup
```sql
-- Creating Table to import EXCEL file
DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist 			VARCHAR(255),
    track 			VARCHAR(255),
    album 			VARCHAR(255),
    album_type 			VARCHAR(50),
    danceability 		FLOAT,
    energy 			FLOAT,
    loudness 			FLOAT,
    speechiness 		FLOAT,
    acousticness 		FLOAT,
    instrumentalness 		FLOAT,
    liveness 			FLOAT,
    valence		 	FLOAT,
    tempo 			FLOAT,
    duration_min 		FLOAT,
    title 			VARCHAR(255),
    channel 			VARCHAR(255),
    views 			FLOAT,
    likes 			BIGINT,
    comments 			BIGINT,
    licensed 			BOOLEAN,
    official_video 		BOOLEAN,
    stream 			BIGINT,
    energy_liveness 		FLOAT,
    most_played_on 		VARCHAR(50)
);

```
### 2. Database Design
The dataset contains attributes such as:
- `artist_name`: The performer of the track.
- `track_name`: The name of the song.
- `album_name`: The album to which the track belongs.
- `album_type`: The type of album (e.g., single or album).
- Various metrics such as `danceability`, `energy`, `loudness`, `tempo`, and more.

**ER diagram of Data Set**: 
![ERD](https://github.com/newgjkk/Spotify_SQL_project/blob/main/Data_Model_Spotify.jpg)

This relational data model was developed to streamline the organization and storage of music streaming data, enabling efficient data extraction and quick retrieval for analysis. Its structured design allows for seamless integration with front-end teams, ensuring data is provided in the required format for creating a dynamic music streaming platform. The model enhances system performance, scalability, and ensures consistent communication between various data tables.



### 3. Data Cleansing, Normalization, and ETL Process 
```sql
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

```





### 4. Data Analysis & Findings
- **Most Streamed Track**: 
```sql
SELECT t.track_name, p.platform_name, SUM(sd.stream) AS total_streams
FROM streaming_data sd
	JOIN tracks t ON sd.track_id = t.track_id
	JOIN platforms p ON sd.platform_id = p.platform_id
GROUP BY t.track_name, p.platform_name
ORDER BY total_streams DESC
LIMIT 10;


```
- **Top 5 Artists with the Most Streams**: 
```sql
SELECT 
	artist,
	SUM(stream)
FROM spotify
GROUP BY artist
ORDER BY SUM(stream) DESC
LIMIT 5;


```
- **Streaming Data for All Tracks of Top 5 Artists**: 
```sql
SELECT 
	art.artist_id,
	art.artist_name,
	tra.track_name,
	sum(stre.stream) as total_stream

FROM artists art
	JOIN albums alb ON art.artist_id = alb.artist_id
	JOIN tracks tra	ON alb.album_id = tra.album_id
	JOIN streaming_data stre ON stre.track_id= tra.track_id
WHERE 
	art.artist_name IN ('Post Malone', 'Ed Sheeran','Dua Lipa','XXXTENTACION','The Weeknd')

GROUP BY
	art.artist_id, art.artist_name,tra.track_name
ORDER BY 
	art.artist_name, sum(stre.stream) DESC;

```
- **Average Streams and Views per Platform**: 
```sql
SELECT p.platform_name, 
       ROUND(AVG(sd.stream),2) AS avg_streams, 
       ROUND(CAST(AVG(sd.views) AS NUMERIC),2) AS avg_views
FROM streaming_data sd
	JOIN platforms p ON sd.platform_id = p.platform_id
GROUP BY p.platform_name;
```

- **Most Streamed Track by Album Type**: 
```sql
WITH ranked_tracks AS (
    SELECT t.track_name, al.album_type, SUM(sd.stream) AS total_streams,
           RANK() OVER(PARTITION BY al.album_type ORDER BY SUM(sd.stream) DESC) AS rank
    FROM streaming_data sd
	    JOIN tracks t ON sd.track_id = t.track_id
	    JOIN albums al ON t.album_id = al.album_id
    GROUP BY t.track_name, al.album_type
)
SELECT track_name, album_type, total_streams
FROM ranked_tracks
WHERE rank = 1  
ORDER BY total_streams DESC;
```
- **Analysis of Tracks with Below-Median Streams**: 
```sql
WITH stream_stats AS (
    SELECT track_id, SUM(stream) AS total_streams
    FROM streaming_data
    GROUP BY track_id
)
SELECT t.track_name, s.total_streams
FROM stream_stats s
	JOIN tracks t ON s.track_id = t.track_id
WHERE 
	s.total_streams != 0 AND
	s.total_streams < (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_streams) 
    FROM stream_stats
)
ORDER BY s.total_streams ASC;
```
- **Correlation Between Stream Count and View Count**: 
```sql
SELECT t.track_name, SUM(sd.views) AS total_views, SUM(sd.stream) AS total_streams
FROM streaming_data sd
	JOIN tracks t ON sd.track_id = t.track_id
GROUP BY t.track_name
ORDER BY total_views DESC;
```
- **Comparison Between Official and Non-Official Music Videos**: 
```sql
WITH cte_off AS(
	SELECT t.track_name, 
		SUM(sd.stream) AS total_streams,
		sd.official_video,
		RANK() OVER(PARTITION BY sd.official_video ORDER BY SUM(sd.stream) DESC) as ranks
	FROM streaming_data sd
		JOIN tracks t ON sd.track_id = t.track_id
	GROUP BY t.track_name, sd.official_video
)
SELECT *
FROM cte_off 
WHERE ranks < 5
ORDER BY official_video, total_streams DESC;
```
- **Average Audio Features by Genre (Album Type)**: 
```sql
SELECT al.album_type, 
       AVG(t.danceability) AS avg_danceability, 
       AVG(t.energy) AS avg_energy,
       AVG(t.acousticness) AS avg_acousticness,
	   COUNT(*),
	   SUM(stream) AS total_stream
FROM tracks t
	JOIN albums al ON t.album_id = al.album_id
	JOIN streaming_data st ON t.track_id = st.track_id
GROUP BY al.album_type
ORDER BY SUM(stream) DESC;
```
---



## Key Insights
- **Artist Performance Analysis**: Top artists (Post Malone, Ed Sheeran, Dua Lipa, etc.) account for a significant portion of total streams. Their tracks have consistently high views and streams across multiple platforms, highlighting their strong influence in the market.

- **Platform Performance Differences**: YouTube has significantly higher views compared to other platforms, with around 250 million more views than Spotify. This indicates that YouTube has a broader user base and suggests the need for platform-specific strategies.

- **Popularity of Single Albums**: Single albums generate over 10 times more streams than full albums. Consumers tend to prefer single tracks, which suggests a shift towards creating more single-focused content to align with market demand.

- **Importance of Official Music Videos**: Tracks with official music videos have at least twice the streams compared to non-official tracks. This emphasizes the crucial role that video content plays in driving streaming performance.

- **Genre-Based Audio Features**: Energetic and danceable tracks tend to have higher stream counts, reflecting consumers' preference for active and upbeat music.

---

## Business Recommendations

- **Differentiate Marketing Strategies by Platform**: Recognizing the differences between platforms like YouTube and Spotify, distinct marketing strategies should be developed for each. Given YouTube's higher viewership, more content and advertising campaigns should be concentrated on this platform.

- **Focus on Single Tracks**: As single albums are more popular than full albums, it is important to prioritize single-track production and marketing. Expanding the offering of single tracks will better align with consumer preferences and increase market share.

- **Increase Investment in Official Music Videos**: Given the positive impact of official music videos on streaming performance, artists and production companies should focus on increasing investment in video production and promotion. Effective use of video content will maximize the reach and success of tracks.

- **Tailor Content to Genre Preferences**: With consumers showing a preference for energetic and danceable music, more tracks featuring these characteristics should be produced. Aligning music production with listener preferences will help attract more listeners and increase engagement.


---

## Conclusion
The findings from this project provide critical insights into music market trends and consumer behavior. Top artists and single tracks dominate streaming activity, and official music videos play a crucial role in enhancing track performance. Additionally, differences in platform behavior indicate that tailored marketing strategies are essential for success.

Based on these insights, focusing on single-track production, increasing official music video content, and developing platform-specific marketing strategies are key actions that can enhance the competitiveness of the music industry. These strategies, combined with a focus on producing tracks that align with consumer preferences, will drive success in this evolving market.
