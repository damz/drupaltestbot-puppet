
class testing_bot {
  # Firewall configuration.
  firewall::rule::allow_servers { "http":
    protocol => tcp,
    port => 80,
    servers => [ "0.0.0.0/0" ],
  }

  # Create the mount point.
  file { "/tmpfs":
    ensure => directory,
  }

  # A wild tmpfs mount.
  mount { "/tmpfs":
    device => "tmpfs",
    atboot => true,
    options => "rw",
    ensure => mounted,
    fstype => "tmpfs",
    require => File["/tmpfs"],
    remounts => false,
  }

  # Backup some important data to disk.
  package { "rsync":
    ensure => present,
  }
  file { "/etc/init.d/disk-backup":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet://$servername/modules/testing_bot/disk-backup",
    require => Package["rsync"],
    notify  => Exec["install-disk-backup"],
  }
  exec { "install-disk-backup":
    path        => "/usr/bin:/bin:/usr/sbin:/sbin",
    command     => "update-rc.d disk-backup defaults 08",
    refreshonly => true,
  }

  # Mysql Configuration, we always install MySQL regardless of the test
  # environment because the test client itself needs that.
  include "mysql::server"

  # Perform the initial backup of the database once MySQL has been installed.
  exec { "initial-backup":
    path        => "/usr/bin:/bin:/usr/sbin:/sbin",
    command     => "/etc/init.d/mysql stop && cp -a /var/lib/mysql /tmpfs/mysql && touch /tmpfs/.backup-done && /etc/init.d/disk-backup stop && /etc/init.d/mysql start",
    creates     => "/tmpfs/.backup-done",
    require     => [ Package["mariadb-server-5.1"], Mount["/tmpfs"], File["/etc/init.d/disk-backup"] ]
  }

  # Move MySQL's data directory to the tmpfs.
  file { "/etc/mysql/conf.d/tmpfs.cnf":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet://$servername/modules/testing_bot/mysql-tmpfs.cnf",
    require => Exec["initial-backup"],
    notify  => Service["mysql"],
  }

  package { ["drush", "apache2", "libapache2-mod-php5", "curl", "cvs"]:
    ensure => present,
  }

  # Drush needs to run one time as root to download its prerequisites from PEAR.
  exec { "init-drush":
    creates => "/etc/drush/.initialized",
    command => "/usr/bin/drush && /usr/bin/touch /etc/drush/.initialized",
    require => Package["drush"],
  }

  service { "apache2":
    require => Package["apache2"],
  }

  # Additional PHP modules.
  package { ["php5", "php5-gd", "php5-apc", "php5-cli", "php5-curl"]:
    ensure => present,
    require => Base::Apt::Repository["php53"],
    notify => Service["apache2"],
  }

  # Enable the rewrite module.
  exec { "a2enmod-rewrite":
    creates => "/etc/apache2/mods-enabled/rewrite.load",
    command => "/usr/sbin/a2enmod rewrite",
    require => Package["apache2"],
    notify  => Service["apache2"],
  }

  file { "/etc/php5/apache2/php.ini":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet://$servername/modules/testing_bot/php.ini",
    require => Package["libapache2-mod-php5"],
    notify  => Service["apache2"],
  }

  file { "/etc/php5/cli/php.ini":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet://$servername/modules/testing_bot/php.ini",
    require => Package["php5-cli"],
  }

  package { "drupaltestbot":
    ensure => "0.0.4",
    require => Exec["initial-backup"],
  }

  class mysql {
    package { "drupaltestbot-mysql":
      ensure => present,
      require => [ Package["drupaltestbot"], Exec["initial-backup"] ],
    }
  }

  class pgsql {
    package { "drupaltestbot-pgsql":
      ensure => present,
      require => Package["drupaltestbot"],
    }
  }

  class sqlite3 {
    package { "drupaltestbot-sqlite3":
      ensure => present,
      require => Package["drupaltestbot"],
    }
  }
}
