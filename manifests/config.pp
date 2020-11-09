# @!visibility private
class yp::config {

  $domain = $::yp::domain

  case $facts['os']['family'] {
    'OpenBSD': {
      file { '/etc/defaultdomain':
        ensure  => file,
        owner   => 0,
        group   => 0,
        mode    => '0644',
        content => "${domain}\n",
      }
    }
    'RedHat': {
      augeas { '/etc/sysconfig/network/NISDOMAIN':
        context => '/files/etc/sysconfig/network',
        changes => [
          'rm NISDOMAIN',
          "set NISDOMAIN ${domain}",
        ],
      }
    }
    default: {
      # noop
    }
  }

  exec { "domainname ${domain}":
    path   => $::path,
    unless => "domainname | grep -q ^${domain}\$",
  }

  file { $::yp::yp_dir:
    ensure => directory,
    owner  => 0,
    group  => 0,
    mode   => '0644',
  }
}
