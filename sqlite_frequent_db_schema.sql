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
/* v_tops(count,path) */;
