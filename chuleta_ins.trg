create temporary trigger chuleta_ins after insert on chuleta 
begin
    insert into chuleta_fts(id, path) values (new.id, new.path);
end;
