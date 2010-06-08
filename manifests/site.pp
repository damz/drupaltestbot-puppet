import "base"

# If the name of the server contains -mysql, use the MySQL profile.
node /-mysql/ {
  include base
  include testing_bot
  include testing_bot::mysql
}

# If the name of the server contains -pgsql, use the PostgreSQL profile.
node /-pgsql/ {
  include base
  include testing_bot
  include testing_bot::pgsql
}

# If the name of the server contains -pgsql, use the SQLite profile.
node /-sqlite3/ {
  include base
  include testing_bot
  include testing_bot::sqlite3
}
