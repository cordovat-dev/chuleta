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
/* v_chuleta_ap(id,path) */;
CREATE TABLE frequent(
        path text primary key not null,
        last_access text,
        count integer not null default 0,
        trigger_it int
);
CREATE VIEW v_frequent as
select
        path,
        last_access,
        count,
        trigger_it
from frequent
/* v_frequent(path,last_access,count,trigger_it) */;
CREATE TRIGGER insert_frequent
    INSTEAD OF INSERT ON v_frequent
BEGIN
    INSERT INTO frequent(path,last_access,count,trigger_it)
    VALUES(new.path,CURRENT_TIMESTAMP,1,new.trigger_it);
END;
CREATE TRIGGER update_frequent
    INSTEAD OF UPDATE ON v_frequent
BEGIN
        UPDATE frequent
        SET
                last_access=CURRENT_TIMESTAMP,
                count=old.count+1,
                trigger_it=new.trigger_it
        WHERE
                path = old.path;
END;
