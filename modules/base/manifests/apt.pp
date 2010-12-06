
class base::apt {
  file { "/etc/apt/apt.conf.d/01recommend":
    content => 'APT::Install-Recommends "0"; APT::Install-Suggests "0";'
  }
  file { "/etc/apt/sources.list.d":
    ensure   => directory,
    owner    => root,
    group    => root,
    mode     => 0755,
  }
  file { "/etc/apt/sources.list":
    ensure => absent,
  }

  exec { "apt-update":
    command => "/usr/bin/apt-get update",
    require => [ File["/etc/apt/apt.conf.d/01recommend"], File["/etc/apt/sources.list"], File["/etc/apt/sources.list.d"] ],
    refreshonly => true,
  }

  define repository($repository_source, $key_source = '', $key_id = '', $ensure = 'present') {
    case $ensure {
      present: {
        file { "/etc/apt/sources.list.d/$name.list":
          source => $repository_source,
          ensure => $ensure,
          notify => Exec["apt-update-$name"],
        }
        if ($key_source) {
          file { "/etc/apt/key-$name":
            source => $key_source,
            ensure => $ensure,
            notify => Exec["import-key-$name"],
          }
          exec { "import-key-$name":
            path        => "/usr/bin:/bin",
            command     => "cat /etc/apt/key-$name | apt-key add -",
            refreshonly => true,
            notify => Exec["apt-update-$name"],
          }
        }
        exec { "apt-update-$name":
          command => "/usr/bin/apt-get update",
          refreshonly => true,
          require => [ File["/etc/apt/apt.conf.d/01recommend"], File["/etc/apt/sources.list"], File["/etc/apt/sources.list.d"] ],
        }
      }
      absent: {
        file { "/etc/apt/sources.list.d/$name":
          ensure => absent,
          notify => Exec["apt-update-$name"],
        }
        if ($key_source) {
          file { "/etc/apt/key-$name":
            ensure => absent,
            notify => Exec["remove-key-$name"],
          }
          exec { "remove-key-$name":
            path => "/usr/bin:/bin",
            command => "apt-key del $key_id",
            refreshonly => true,
            notify => Exec["apt-update-$name"],
          }
        }
        exec { "apt-update-$name":
          command => "/usr/bin/apt-get update",
          refreshonly => true,
          require => [ File["/etc/apt/apt.conf.d/01recommend"], File["/etc/apt/sources.list"], File["/etc/apt/sources.list.d"] ],
        }
      }
    }
  }

}
