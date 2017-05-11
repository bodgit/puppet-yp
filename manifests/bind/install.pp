# @!visibility private
class yp::bind::install {

  if $::yp::bind::manage_package {
    package { $::yp::bind::package_name:
      ensure => present,
    }
  }
}
