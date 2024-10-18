
---------- Most Streamed Track ---------- 
SELECT t.track_name, p.platform_name, SUM(sd.stream) AS total_streams
FROM streaming_data sd
	JOIN tracks t ON sd.track_id = t.track_id
	JOIN platforms p ON sd.platform_id = p.platform_id
GROUP BY t.track_name, p.platform_name
ORDER BY total_streams DESC
LIMIT 10;

SELECT * FROM spotify;

---------- Top 5 Artists with the Most Streams ----------
SELECT 
	artist,
	SUM(stream)
FROM spotify
GROUP BY artist
ORDER BY SUM(stream) DESC
LIMIT 5;

---------- Streaming Data for All Tracks of Top 5 Artists ---------- 
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



---------- Average Streams and Views per Platform ----------
SELECT p.platform_name, 
       ROUND(AVG(sd.stream),2) AS avg_streams, 
       ROUND(CAST(AVG(sd.views) AS NUMERIC),2) AS avg_views
FROM streaming_data sd
	JOIN platforms p ON sd.platform_id = p.platform_id
GROUP BY p.platform_name;


---------- Most Streamed Track by Album Type ----------
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

---------- Analysis of Tracks with Below-Median Streams ----------
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


---------- Correlation Between Stream Count and View Count ----------
SELECT t.track_name, SUM(sd.views) AS total_views, SUM(sd.stream) AS total_streams
FROM streaming_data sd
	JOIN tracks t ON sd.track_id = t.track_id
GROUP BY t.track_name
ORDER BY total_views DESC;

---------- Comparison Between Official and Non-Official Music Videos ---------- 
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

----------  Average Audio Features by Genre (Album Type) ---------- 
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



