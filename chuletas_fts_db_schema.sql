CREATE VIRTUAL TABLE "chuleta_fts" USING FTS5 (
                id,
        "path",
        content
)
/* chuleta_fts(id,path,content) */;
CREATE TABLE IF NOT EXISTS 'chuleta_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'chuleta_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'chuleta_fts_content'(id INTEGER PRIMARY KEY, c0, c1, c2);
CREATE TABLE IF NOT EXISTS 'chuleta_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'chuleta_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
