CREATE TABLE frequent(
        path text,
        count integer
);
CREATE VIEW v_tops as
select count, path 
from
	frequent
where count > (
	select 
		avg(count)
	from 
		frequent
	where 
		count > (select avg(count) from frequent)
) order by count desc
/* v_tops(count,path) */
/* v_tops(count,path) */;
CREATE TABLE frequent_log(path text, count integer);
CREATE VIEW v_log_count as select path, count(*) count from frequent_log group by path
/* v_log_count(path,count) */;
CREATE VIEW v_log_summary  as select count, path
from
        v_log_count
where count > (
        select
                avg(count)
        from
                v_log_count
        where
                count > (select avg(count) from v_log_count)
) order by count desc
/* v_log_summary(count,path) */;
CREATE TABLE settings (key text primary key not null, value text);
