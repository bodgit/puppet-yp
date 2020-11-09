# @!visibility private
class yp::bind::service {

  service { $::yp::bind::service_name:
    ensure     => $::yp::bind::service_ensure,
    enable     => $::yp::bind::service_enable,
    hasstatus  => true,
    hasrestart => true,
  }
}
