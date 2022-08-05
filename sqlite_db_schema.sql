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
