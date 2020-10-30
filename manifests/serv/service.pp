# @!visibility private
class yp::serv::service {

  service { $yp::serv::ypserv_service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  if $yp::serv::has_yppasswdd {

    $yppasswdd_ensure = $yp::serv::master ? {
      undef   => running,
      default => stopped,
    }
    $yppasswdd_enable = $yp::serv::master ? {
      undef   => true,
      default => false,
    }

    service { $yp::serv::yppasswdd_service_name:
      ensure     => $yppasswdd_ensure,
      enable     => $yppasswdd_enable,
      hasstatus  => true,
      hasrestart => true,
    }
  }

  if $yp::serv::has_ypxfrd {

    $ypxfrd_ensure = size($yp::serv::slaves) ? {
      0       => stopped,
      default => running,
    }
    $ypxfrd_enable = size($yp::serv::slaves) ? {
      0       => false,
      default => true,
    }

    service { $yp::serv::ypxfrd_service_name:
      ensure     => $ypxfrd_ensure,
      enable     => $ypxfrd_enable,
      hasstatus  => true,
      hasrestart => true,
    }
  }
}
