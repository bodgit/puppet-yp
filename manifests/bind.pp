# Class for installing and managing `ypbind` daemon.
#
# @example Declaring the class
#   include ::portmap
#
#   class { '::yp':
#     domain => 'example.com',
#   }
#
#   class { '::yp::bind':
#     domain  => 'example.com',
#     servers => [
#       '192.0.2.1',
#       '192.0.2.2',
#       '192.0.2.3',
#     ],
#   }
#
#   Class['::portmap'] ~> Class['::yp::bind'] <~ Class['::yp']
#
#   if $::osfamily == 'RedHat' {
#     class { '::nsswitch':
#       passwd    => ['files', 'nis', 'sss'],
#       shadow    => ['files', 'nis', 'sss'],
#       group     => ['files', 'nis', 'sss'],
#       hosts     => ['files', 'nis', 'dns'],
#       netgroup  => ['files', 'nis', 'sss'],
#       automount => ['files', 'nis'],
#       require   => Class['::yp::bind'],
#     }
#
#     pam { 'nis':
#       ensure    => present,
#       service   => 'system-auth-ac',
#       type      => 'password',
#       control   => 'sufficient',
#       module    => 'pam_unix.so',
#       arguments => [
#         'md5',
#         'shadow',
#         'nis',
#         'nullok',
#         'try_first_pass',
#         'use_authtok',
#       ],
#       require   => Class['::yp::bind'],
#     }
#   }
#
# @param domain The YP/NIS domain.
# @param servers An array of YP servers to use, if left undefined will default
#   to broadcasting.
# @param manage_package Whether to manage a package or not. Some operating
#   systems have `ypbind` as part of the base system.
# @param package_name The name of the package.
# @param service_enable
# @param service_ensure
# @param service_name The name of the service managing `ypbind`.
#
# @see puppet_classes::yp ::yp
# @see puppet_classes::yp::serv ::yp::serv
# @see puppet_classes::yp::ldap ::yp::ldap
class yp::bind (
  String                                    $domain,
  Optional[Array[IP::Address::NoSubnet, 1]] $servers        = undef,
  Boolean                                   $manage_package = $::yp::params::bind_manage_package,
  Optional[String]                          $package_name   = $::yp::params::bind_package_name,
  Boolean                                   $service_enable = $::yp::params::bind_service_enable,
  Enum['running', 'stopped']                $service_ensure = $::yp::params::bind_service_ensure,
  String                                    $service_name   = $::yp::params::bind_service_name,
) inherits yp::params {

  contain yp::bind::install
  contain yp::bind::config
  contain yp::bind::service

  Class['yp::bind::install'] -> Class['yp::bind::config']
    ~> Class['yp::bind::service']
}
