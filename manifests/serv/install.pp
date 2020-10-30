# @!visibility private
class yp::serv::install {

  if $yp::serv::manage_package {
    package { $yp::serv::package_name:
      ensure => present,
    }
  }
}
