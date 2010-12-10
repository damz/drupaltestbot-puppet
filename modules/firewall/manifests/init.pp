
# A set of simple rules around iptables.

class firewall {
  File {
    owner => root,
    group => root,
    mode => 644,
  }
  file { "/etc/init.d/firewall":
    source  => "puppet:///modules/firewall/init.d/firewall",
    mode => 755,
    notify => Service["firewall"]
  }
  file { "/etc/default/firewall":
    source  => "puppet:///modules/firewall/default/firewall",
  }
  file { "/etc/firewall.d":
    ensure => "directory",
  }
  file { "/etc/firewall.d/00clear":
    source  => "puppet:///modules/firewall/firewall.d/00clear",
    mode => 755,
  }
  file { "/etc/firewall.d/05policies":
    source  => "puppet:///modules/firewall/firewall.d/05policies",
    mode => 755,
  }

  service { "firewall":
    enable => true,
    require => File["/etc/init.d/firewall"],
  }
}

define firewall::rule($ensure = "present", $content) {
  file { "/etc/firewall.d/50$name":
    owner => root,
    group => root,
    mode => 755,
    content => template("firewall/rule.rb"),
    ensure => $ensure,
    notify => Service["firewall"],
  }
}

define firewall::rule::allow_servers($ensure = "present", $protocol, $port, $servers) {
  file { "/etc/firewall.d/50$name":
    owner => root,
    group => root,
    mode => 755,
    content => template("firewall/allow_servers.rb"),
    ensure => $ensure,
    notify => Service["firewall"],
  }
}
