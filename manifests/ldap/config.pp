# @!visibility private
class yp::ldap::config {

  $domain          = $::yp::ldap::domain
  $interval        = $::yp::ldap::interval
  $maps            = $::yp::ldap::maps
  $tls_cacert_file = $::yp::ldap::tls_cacert_file

  ::concat { $::yp::ldap::conf_file:
    owner        => 0,
    group        => 0,
    mode         => '0640',
    warn         => "# !!! Managed by Puppet !!!\n",
    validate_cmd => '/usr/sbin/ypldap -n -f %',
  }

  ::concat::fragment { "${::yp::ldap::conf_file} global":
    order   => '01',
    content => template("${module_name}/ypldap.conf.global.erb"),
    target  => $::yp::ldap::conf_file,
  }

  $::yp::ldap::directories.each |$resource, $attributes| {
    ::yp::ldap::directory { $resource:
      * => $attributes,
    }
  }
}
