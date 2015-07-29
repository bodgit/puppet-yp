#
class yp::serv::config {

  $domain       = $::yp::serv::domain
  $maps         = $::yp::serv::maps
  $master       = $::yp::serv::master
  $merge_group  = $::yp::serv::merge_group
  $merge_passwd = $::yp::serv::merge_passwd
  $minimum_gid  = $::yp::serv::minimum_gid
  $minimum_uid  = $::yp::serv::minimum_uid
  $yp_dir       = $::yp::serv::yp_dir
  $slaves       = $::yp::serv::slaves

  file { "${yp_dir}/${domain}":
    ensure => directory,
    owner  => 0,
    group  => 0,
    mode   => '0644',
  }

  if $master {
    $_maps = flatten([$maps, 'ypservers'])
  } else {

    $targets = yp_map_to_make_target($maps)
    $_maps   = $maps

    case $::osfamily { # lint:ignore:case_without_default
      'OpenBSD': {
        file { "${yp_dir}/Makefile":
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => template('yp/Makefile.main.erb'),
        }

        file { "${yp_dir}/${domain}/Makefile":
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => template('yp/Makefile.yp.erb'),
        }
      }
      'RedHat': {
        file { "${yp_dir}/Makefile":
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => template('yp/Makefile.erb'),
        }
      }
    }

    file { "${yp_dir}/ypservers":
      owner   => 0,
      group   => 0,
      mode    => '0644',
      content => template('yp/ypservers.erb'),
    }

    # Not sure I like this but it's essentially how the map is built
    exec { "awk '{ if (\$1 != \"\" && \$1 !~ \"#\") print \$0\"\\t\"\$0 }' ${yp_dir}/ypservers | makedbm - ${yp_dir}/${domain}/ypservers": # lint:ignore:80chars
      path        => [
        '/sbin',
        '/usr/sbin',
        '/bin',
        '/usr/bin',
        '/usr/lib/yp',
        '/usr/lib64/yp',
      ],
      refreshonly => true,
      require     => File["${yp_dir}/${domain}"],
      subscribe   => File["${yp_dir}/ypservers"],
    }
  }

  ::yp::serv::map { $_maps:
    domain    => $domain,
    extension => $::yp::serv::map_extension,
    master    => $master,
    yp_dir    => $yp_dir,
  }
}
