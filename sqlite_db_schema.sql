CREATE TABLE IF NOT EXISTS "chuleta" (
                id INTEGER PRIMARY KEY NOT NULL DEFAULT ROWID,
        "path"  TEXT NOT NULL
);
CREATE TABLE settings(
        key text primary key not null,
        value text
);
CREATE VIEW v_chuleta_ap as
select
        c.id,
		c.path rel_path,
        s.value||'/'||c.path abs_path
from
        chuleta c,
        (select value from settings where key = 'BASE_DIR') s
order by
        c.id;
CREATE VIEW v_old_db_msg as
select
	'Database is '||cast(d.age as int)||' days old. Please run chu --update .' msg
from
        (
                select
                        (julianday(CURRENT_TIMESTAMP) - julianday(value)) >=
                        (select value from settings where key='NUM_DAYS_OLD') old,
                        (julianday(CURRENT_TIMESTAMP) - julianday(value)) age
                from
                        settings
                where
                        key = 'LAST_UPDATED'
        ) d
        join (
                select 1 old
        ) m on (d.old = m.old)
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

