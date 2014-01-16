require "uri"
require "pg"

db_uri = URI.parse(ENV["DATABASE_URL"] || "postgres://localhost:5432/kindle_highlights_dev")
conn = PG.connect(db_uri.host, db_uri.port, nil, nil, db_uri.path[1..-1], nil, nil)

a = conn.exec("DROP TABLE IF EXISTS books");
conn.exec("DROP TABLE IF EXISTS highlights");
conn.exec("
  CREATE TABLE books(
    id SERIAL UNIQUE,
    asin VARCHAR NOT NULL,
    title VARCHAR NOT NULL
  )
");
conn.exec("
  CREATE TABLE highlights(
    id SERIAL,
    book_id INTEGER NOT NULL,
    location INTEGER NOT NULL,
    text TEXT NOT NULL
  )
");