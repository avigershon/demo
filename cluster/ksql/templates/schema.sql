-- lets the windows accumulate more data
set 'commit.interval.ms'='2000';
set 'cache.max.bytes.buffering'='10000000';
set 'auto.offset.reset'='earliest';


-- 1. SOURCE of SPORT EVENTS
DROP STREAM IF EXISTS sport_events;

CREATE STREAM sport_events(name varchar, source_name varchar,keywords varchar,league_name varchar,sport_name varchar,minute int, date bigint,score varchar, score_1 varchar, score_2 varchar, timestamp bigint, id varchar) with (kafka_topic = 'SPORT_EVENT', value_format = 'json', KEY='id', TIMESTAMP='timestamp');

DROP TABLE IF EXISTS sport_events_per_min;
CREATE table sport_events_per_min AS SELECT name, source_name, league_name, sport_name, minute, date, score, score_1, score_2, timestamp, id, count(*) AS events FROM sport_events window TUMBLING (size 60 second) GROUP BY name, source_name, league_name, sport_name, minute, date, score, score_1, score_2, timestamp, id;
