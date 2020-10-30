# @!visibility private
class yp::ldap::service {

  service { $yp::ldap::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
