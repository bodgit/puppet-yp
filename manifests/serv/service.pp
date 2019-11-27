# @!visibility private
class yp::serv::service {

  service { $::yp::serv::ypserv_service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  if $::yp::serv::has_yppasswdd {

    $yppasswdd_ensure = $::yp::serv::master ? {
      undef   => running,
      default => stopped,
    }
    $yppasswdd_enable = $::yp::serv::master ? {
      undef   => true,
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

    #puppet6 does not allow size() arg to be undef, and array size is either greater than 1 thanks to parameter validation, or undef.
    # empty array is not allowed.
    if( $::yp::serv::slaves ) {
      $ypxfrd_ensure = 'running'
      $ypxfrd_enable = true
    } else {
      $ypxfrd_ensure = 'stopped'
      $ypxfrd_enable = false
    }

    service { $::yp::serv::ypxfrd_service_name:
      ensure     => $ypxfrd_ensure,
      enable     => $ypxfrd_enable,
      hasstatus  => true,
      hasrestart => true,
    }
  }
}
