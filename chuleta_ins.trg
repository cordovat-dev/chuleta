create temporary trigger chuleta_ins after insert on chuleta 
begin
    insert or replace into chuleta_fts(id, path, content) 
    values (
        new.id, 
        new.path,
        readfile(
            (select value from settings where key = 'BASE_DIR')
            ||'/'||
            new.path)
        );
end;
