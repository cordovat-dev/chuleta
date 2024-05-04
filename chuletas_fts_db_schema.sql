CREATE TABLE IF NOT EXISTS "chuleta_fts" (
                id INTEGER PRIMARY KEY NOT NULL DEFAULT ROWID,
        "path"  TEXT NOT NULL,
        constraint chuleta_u unique(path)
);
