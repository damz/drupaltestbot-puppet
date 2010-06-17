
class pgsql {
  class server {
    # TODO: Sort out locales, which are breaking pg_createcluster

    file { "/etc/sysctl.d/shmmax.conf":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet://$servername/modules/pgsql/shmmax.conf",
      require => Package["postgresql-8.3"],
      notify  => Exec["shmmax-sysctl"]
    }

    exec { "shmmax-sysctl":
      path    => "/usr/bin:/bin:/usr/sbin:/sbin",
      command => "/sbin/sysctl -p /etc/sysctl.d/shmmax.conf",
    }

    package { "postgresql-8.3":
      ensure  => present,
      require => Base::Apt::Repository["lenny"],
    }

    service { "postgresql-8.3":
      enable  => true,
      require => Package["postgresql-8.3"],
    }

    file { "/etc/postgresql/8.3/main/postgresql.conf":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet://$servername/modules/pgsql/postgresql.conf",
      require => Package["postgresql-8.3"], Exec["initial-backup-pg"], File["/etc/sysctl.d/shmmax.conf"],
      notify  => Service["postgresql-8.3"],
    }

    file { "/etc/postgresql/8.3/main/pg_hba.conf":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet://$servername/modules/pgsql/pg_hba.conf",
      require => Package["postgresql-8.3"],
      notify  => Service["postgresql-8.3"],
    }

    # Perform the initial backup of the database once PostgreSQL has been installed.
    exec { "initial-backup-pg":
      path        => "/usr/bin:/bin:/usr/sbin:/sbin",
      command     => "/etc/init.d/postgresql-8.3 stop && cp -a /var/lib/postgresql /tmpfs/postgresql && touch /tmpfs/.pg-backup-done && /etc/init.d/disk-backup stop && /etc/init.d/postgresql-8.3 start",
      creates     => "/tmpfs/.pg-backup-done",
      require     => [ Package["postgresql-8.3"], Mount["/tmpfs"], File["/etc/init.d/disk-backup"] ]
    }
  }
}