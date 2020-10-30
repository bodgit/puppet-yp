# @!visibility private
class yp::bind::service {

  service { $yp::bind::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
