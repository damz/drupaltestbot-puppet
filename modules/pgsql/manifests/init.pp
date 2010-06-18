
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
      require => File["/etc/sysctl.d/shmmax.conf"]
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
      require => [ Package["postgresql-8.3"], Exec["pg-tmpfs-init"], File["/etc/sysctl.d/shmmax.conf"] ],
      notify  => Service["postgresql-8.3"],
    }

    file { "/etc/postgresql/8.3/main/pg_hba.conf":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet://$servername/modules/pgsql/pg_hba.conf",
      require => Exec["pg-tmpfs-init"],
      notify  => Service["postgresql-8.3"],
    }

    # Shift the "main" postgres cluster on to tmpfs and reinit
    exec { "pg-tmpfs-init":
      path        => "/usr/bin:/bin:/usr/sbin:/sbin",
      command     => "/usr/bin/pg_dropcluster --stop 8.3 main && /usr/bin/pg_createcluster -d /tmpfs/postgresql/8.3/main --start 8.3 main",
      creates     => "/tmpfs/postgresql/8.3/main/PG_VERSION",
      require     => Package["postgresql-8.3"],
      notify      => Exec["initial-backup-pg"]
    }

    # Perform the initial backup of the database once PostgreSQL has been installed.
    exec { "initial-backup-pg":
      path        => "/usr/bin:/bin:/usr/sbin:/sbin",
      command     => "/etc/init.d/postgresql-8.3 stop && touch /tmpfs/.pg-backup-done && /etc/init.d/disk-backup stop && /etc/init.d/postgresql-8.3 start",
      creates     => "/tmpfs/.pg-backup-done",
      require     => [ Exec["pg-tmpfs-init"], Mount["/tmpfs"], File["/etc/init.d/disk-backup"] ]
    }
  }
}