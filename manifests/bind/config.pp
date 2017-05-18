# @!visibility private
class yp::bind::config {

  $domain  = $::yp::bind::domain
  $servers = $::yp::bind::servers

  case $::osfamily {
    'OpenBSD': {
      file { '/etc/yp':
        ensure  => directory,
        owner   => 0,
        group   => 0,
        mode    => '0644',
        purge   => true,
        recurse => true,
      }

      if $servers {
        file { "/etc/yp/${domain}":
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => template("${module_name}/domain.erb"),
        }
      }

      # Use augeas to add the '+:*::::::::' record to /etc/master.passwd
      augeas { '/etc/master.passwd/nisdefault':
        context => '/files/etc/master.passwd',
        changes => [
          'clear @nisdefault',
          'set @nisdefault/password "*"',
          'set @nisdefault/uid ""',
          'set @nisdefault/gid ""',
          'clear @nisdefault/class',
          'set @nisdefault/change_date ""',
          'set @nisdefault/expire_date ""',
          'clear @nisdefault/name',
          'clear @nisdefault/home',
          'clear @nisdefault/shell',
        ],
      }

      exec { 'pwd_mkdb -p /etc/master.passwd':
        path        => $::path,
        refreshonly => true,
        subscribe   => Augeas['/etc/master.passwd/nisdefault'],
      }

      # Use augeas to add the '+:::' record to /etc/group
      augeas { '/etc/group/nisdefault':
        context => '/files/etc/group',
        changes => [
          'clear @nisdefault',
          'set @nisdefault/password "*"',
          'set @nisdefault/gid ""',
        ],
      }

      if versioncmp($::augeasversion, '1.4.0') < 0 {
        file { '/usr/local/share/augeas/lenses/passwd.aug':
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => file("${module_name}/passwd.aug"),
        }
      }

      if versioncmp($::augeasversion, '1.5.0') < 0 {
        file { '/usr/local/share/augeas/lenses/masterpasswd.aug':
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => file("${module_name}/masterpasswd.aug"),
          before  => Augeas['/etc/master.passwd/nisdefault'],
        }

        file { '/usr/local/share/augeas/lenses/group.aug':
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => file("${module_name}/group.aug"),
          before  => Augeas['/etc/group/nisdefault'],
        }
      }
    }
    'RedHat': {
      file { '/etc/yp.conf':
        ensure  => file,
        owner   => 0,
        group   => 0,
        mode    => '0644',
        content => template("${module_name}/yp.conf.erb"),
      }
    }
    default: {
      # noop
    }
  }
}
