
class mysql {
  package { "maatkit":
    ensure => present,
  }

  class server {
    package { "mariadb-server-5.1":
      ensure => present,
      require => Base::Apt::Repository["drupal.org"],
    }

    service { "mysql":
      enable => true,
      require => Package["mariadb-server-5.1"],
    }

    file { "/etc/mysql/my.cnf":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet://$servername/modules/mysql/my.cnf",
      require => Package["mariadb-server-5.1"],
      notify  => Service["mysql"],
    }

    file { "/etc/mysql/conf.d/tuning.cnf":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet://$servername/modules/mysql/tuning.cnf",
      require => Package["mariadb-server-5.1"],
      notify  => Service["mysql"],
    }
  }
}
