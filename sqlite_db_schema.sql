CREATE TABLE IF NOT EXISTS "chuleta" (
                id INTEGER PRIMARY KEY NOT NULL DEFAULT ROWID,
        "path"  TEXT NOT NULL,
        constraint chuleta_u unique(path)
);
CREATE TABLE settings(
        key text primary key not null,
        value text
);
CREATE VIEW v_old_db_msg as
select
        'Database is '||cast(d.age as int)||' days old. Please run chu --update .' msg
from
        (
			select
				(julianday(CURRENT_TIMESTAMP) - julianday(value)) >=
				cast((select value from settings where key='NUM_DAYS_OLD') as int) old,
				(julianday(CURRENT_TIMESTAMP) - julianday(value)) age
			from
				settings
			where
				key = 'LAST_UPDATED'
        ) d
        join (
                select 1 old
        ) m on (d.old = m.old);

/* v_old_db_msg(msg) */
/* v_old_db_msg(msg) */;
CREATE VIEW v_totals as 
select 
	t1.main_topic,
	t1.count,
	cast(round(cast(t1.count as real)/cast(t2.total as real)*100,0) as int) pc
from
	(
		select 
			substr(path,1,instr(c.path,'/')-1) main_topic, 
			count(*) count
		from 
			chuleta c
		group by 
			main_topic 
	) t1
	join (select count(*) total from chuleta) t2 
order by 
	t1.count desc
/* v_totals(main_topic,count,pc) */;
CREATE VIEW v_totals_g as
select
        t1.main_topic,
        t1.count,
        t1.pc,
		case when pc < 2 then '-'
		else printf('%.*c', t1.pc/2, '=') end bar
from v_totals t1
order by
        t1.count desc
/* v_totals_g(main_topic,count,pc,bar) */;
CREATE VIEW v_chuleta_ap as
select
        c.id,
		c.path rel_path,
        s.value||'/'||c.path abs_path
from
        chuleta c,
        (select value from settings where key = 'BASE_DIR') s
order by
        c.id
/* v_chuleta_ap(id,rel_path,abs_path) */;
CREATE VIEW v_git_repos as
select r.key, r.value path, cast(ifnull(p.value,0) as int) use_preffix
from settings r
left joIn (select key,value from settings where key like 'PREF_GIT_REPO%') p
on (p.key = 'PREF_'||r.key)
where
	r.key like 'GIT_REPO%'
/* v_git_repos("key",path,use_preffix) */;
create view v_settings_report as
select keyval from (
	select key||'='||datetime(value,'localtime') keyval from settings where key in ('LAST_UPDATED','LAST_UPDATED_AC')
	union
	select key||'='||value keyval from settings where key not in ('LAST_UPDATED','LAST_UPDATED_AC')
) order by keyval;
