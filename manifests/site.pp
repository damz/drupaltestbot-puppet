
import "base"

node "qa-3.damz.org" {
  include base
  include testing_bot
  include testing_bot::mysql
}

node /\.mysql\.drupal-testing\.local$/ {
  include base
  include testing_bot
  include testing_bot::mysql
}

node /\.pgsql\.drupal-testing\.local$/ {
  include base
  include testing_bot
  include testing_bot::pgsql
}

node /\.sqlite3\.drupal-testing\.local$/ {
  include base
  include testing_bot
  include testing_bot::sqlite3
}
