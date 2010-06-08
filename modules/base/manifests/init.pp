# Parent class for all systems.
# Configure APT repositories and ensure freshness of packages.
class base {
  include "base::apt"

  Package {
    require => [ Exec["apt-update"] ],
  }

  base::apt::repository { "lenny":
    repository_source => "puppet://$servername/modules/base/lenny.sources.list",
  }

  base::apt::repository { "backports":
    repository_source => "puppet://$servername/modules/base/backports.sources.list",
    key_source => "puppet://$servername/modules/base/backports.public.key",
    key_id => "16BA136C",
  }

  base::apt::repository { "drupal.org":
    repository_source => "puppet://$servername/modules/base/drupal.sources.list",
    key_source => "puppet://$servername/modules/base/drupal.public.key",
    key_id => "A19A51A2",
  }

  # MOTD configuration.
  file { "/etc/motd.tail":
    source => "puppet://$servername/modules/base/motd.tail",
  }

  # Firewall configuration.
  include "firewall"

  # Locales configuration.
  file { "/etc/locale.gen":
    source => "puppet://$servername/modules/base/locales/locale.gen",
    require => Package["locales"],
    notify => Exec["locale-gen"],
  }
  file { "/etc/default/locale":
    source => "puppet://$servername/modules/base/locales/locale",
    require => Package["locales"],
  }
  exec { "locale-gen":
    path        => "/usr/bin:/bin:/usr/sbin:/sbin",
    command     => "locale-gen",
    refreshonly => true,
  }

  # Login configuration.
  package { "locales": }
  file { "/etc/login.defs":
    owner   => root,
    group   => root,
    mode    => 644,
    source  => "puppet://$servername/modules/base/login.defs",
  }

  # Sudo configuration.
  package { "sudo":
    ensure => present,
  }
  file { "/etc/sudoers":
    owner   => root,
    group   => root,
    mode    => 440,
    source  => "puppet://$servername/modules/base/sudoers",
    require => Package["sudo"],
  }

  # SSH configuration.
  package { "openssh-server":
    ensure => present,
  }
  service { "ssh":
    pattern => "/usr/sbin/sshd",
    hasrestart => true,
    hasstatus => true,
    require => Package["openssh-server"]
  }
  file { "/etc/ssh/sshd_config":
    source => "puppet://$servername/modules/base/sshd_config",
    require => Package["openssh-server"],
    notify => Service["ssh"]
  }

  # Firewall configuration.
  firewall::rule::allow_servers { "ssh":
    protocol => tcp,
    port => ssh,
    servers => [ "0.0.0.0/0" ],
  }
}
