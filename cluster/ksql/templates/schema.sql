-- lets the windows accumulate more data
set 'commit.interval.ms'='2000';
set 'cache.max.bytes.buffering'='10000000';
set 'auto.offset.reset'='earliest';


-- 1. SOURCE of SPORT EVENTS
DROP STREAM IF EXISTS sport_events;

CREATE STREAM sport_events(name varchar, source_name varchar,keywords varchar,league_name varchar,sport_name varchar,minute int, date bigint,score varchar, score_1 varchar, score_2 varchar, timestamp bigint, id varchar, sg map<VARCHAR, VARCHAR>) with (kafka_topic = 'SPORT_EVENT', value_format = 'json', KEY='id', TIMESTAMP='timestamp');

DROP TABLE IF EXISTS sport_events_unique_per_min_unique;
CREATE table sport_events_unique_per_min_unique AS SELECT name,max(minute) minute, id, count(*) AS events FROM sport_events window TUMBLING (size 60 second) GROUP BY id;

select name,minute,EXTRACTJSONFIELD(sg['1'],'$.ft.ah[0][0][0]') as ah_0_id,EXTRACTJSONFIELD(sg['1'],'$.ft.ah[0][0][1]') as ah_0_money_line,EXTRACTJSONFIELD(sg['1'],'$.ft.ah[0][0][2]') as ah_0_run_line,EXTRACTJSONFIELD(sg['1'],'$.ft.ah[0][1][0]') as ah_1_id,EXTRACTJSONFIELD(sg['1'],'$.ft.ah[0][1][1]') as ah_1_money_line,EXTRACTJSONFIELD(sg['1'],'$.ft.ah[0][1][2]') as ah_1_run_line from sport_events;

DROP STREAM IF EXISTS sport_events_per_min;
CREATE STREAM sport_events_per_min WITH (PARTITIONS=4) AS SELECT name, source_name, league_name, sport_name, sport_events.minute as minute, date, score, score_1, score_2, timestamp, sport_events.id AS id, events FROM sport_events LEFT JOIN sport_events_unique_per_min_unique ON sport_events.id = sport_events_unique_per_min_unique.id PARTITION BY sport_events.id; 

//AND sport_events.minute=sport_events_unique_per_min_unique.minute;
