# @!visibility private
define yp::serv::map (
  String                                  $domain,
  Optional[String]                        $extension,
  Optional[Stdlib::IP::Address::NoSubnet] $master,
  Stdlib::Absolutepath                    $yp_dir,
  String                                  $map       = $name,
) {

  if $master {
    exec { "ypxfr -h ${master} -c -d ${domain} ${map}":
      path    => "${::path}:/usr/lib/yp:/usr/lib64/yp",
      creates => "${yp_dir}/${domain}/${map}${extension}",
      require => File["${yp_dir}/${domain}"],
    }
  } else {
    $target = yp::map_to_make_target($map)

    case $facts['os']['family'] {
      'OpenBSD': {
        $make     = "make ${target}"
        $makefile = "${yp_dir}/${domain}/Makefile"
      }
      'RedHat': {
        $make     = "make -f ../Makefile ${target}"
        $makefile = "${yp_dir}/Makefile"
      }
      default: {
        # noop
      }
    }

    # The exec is created and tested against the first map generated from the
    # associated database, i.e. for passwd.byname and passwd.byuid, the exec
    # will be created to only check that passwd.byname.db is created on disk
    if ! defined(Exec[$make]) {
      exec { $make:
        path    => "${::path}:/usr/lib/yp:/usr/lib64/yp",
        cwd     => "${yp_dir}/${domain}",
        creates => "${yp_dir}/${domain}/${map}${extension}",
        require => File[$makefile],
      }
    }
  }
}
