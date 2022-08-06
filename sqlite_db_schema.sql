CREATE TABLE IF NOT EXISTS "chuleta" (
                id INTEGER PRIMARY KEY NOT NULL DEFAULT ROWID,
        "path"  TEXT NOT NULL
);
CREATE TABLE settings(
        cod_set text primary key not null,
        value text
);
CREATE VIEW v_chuleta_ap as
select
        c.id,
        s.value||'/'||c.path path
from
        chuleta c,
        (select value from settings where cod_set = 'BASE_DIR') s
order by
        c.id
/* v_chuleta_ap(id,path) */
/* v_chuleta_ap(id,path) */;
CREATE VIEW v_old_db_msg as
select
	'Database is '||cast(d.age as int)||' days old. Please run chu --update .' msg
from
        (
                select
                        (julianday(CURRENT_TIMESTAMP) - julianday(value)) >=
                        (select value from settings where cod_set='NUM_DAYS_OLD') old,
                        (julianday(CURRENT_TIMESTAMP) - julianday(value)) age
                from
                        settings
                where
                        cod_set = 'LAST_UPDATED'
        ) d
        join (
                select 1 old
        ) m on (d.old = m.old)
/* v_old_db_msg(msg) */;
