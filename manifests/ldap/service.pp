# @!visibility private
class yp::ldap::service {

  service { $::yp::ldap::service_name:
    ensure     => $::yp::ldap::service_ensure,
    enable     => $::yp::ldap::service_enable,
    hasstatus  => true,
    hasrestart => true,
  }
}
