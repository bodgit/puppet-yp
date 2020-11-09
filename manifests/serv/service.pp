# @!visibility private
class yp::serv::service {

  service { $::yp::serv::ypserv_service_name:
    ensure     => $::yp::serv::service_ensure,
    enable     => $::yp::serv::service_enable,
    hasstatus  => true,
    hasrestart => true,
  }

  if $::yp::serv::has_yppasswdd {

    $yppasswdd_ensure = $::yp::serv::master ? {
      undef   => $::yp::serv::service_ensure,
      default => stopped,
    }
    $yppasswdd_enable = $::yp::serv::master ? {
      undef   => $::yp::serv::service_enable,
      default => false,
    }

    service { $::yp::serv::yppasswdd_service_name:
      ensure     => $yppasswdd_ensure,
      enable     => $yppasswdd_enable,
      hasstatus  => true,
      hasrestart => true,
    }
  }

  if $::yp::serv::has_ypxfrd {

    $ypxfrd_ensure = $::yp::serv::slaves ? {
      undef   => stopped,
      default => $::yp::serv::service_ensure,
    }
    $ypxfrd_enable = $::yp::serv::slaves ? {
      undef   => false,
      default => $::yp::serv::service_enable,
    }

    service { $::yp::serv::ypxfrd_service_name:
      ensure     => $ypxfrd_ensure,
      enable     => $ypxfrd_enable,
      hasstatus  => true,
      hasrestart => true,
    }
  }
}
