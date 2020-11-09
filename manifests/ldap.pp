# Class for installing and managing `ypldap` daemon.
#
# This is for OpenBSD only and is the equivalent of PAM/LDAP on Linux.
#
# @example Declaring the class
#   include ::portmap
#
#   class { '::yp::ldap':
#     domain      => 'example.com',
#     directories => {
#       'dc=example,dc=com' => {
#         'server'  => '192.0.2.1',
#         'bind_dn' => 'cn=ypldap,dc=example,dc=com',
#         'bind_pw' => 'secret',
#       },
#     },
#   }
#
#   class { '::yp':
#     domain => 'example.com',
#   }
#
#   class { '::yp::bind':
#     domain => 'example.com',
#   }
#
#   Class['::portmap'] ~> Class['::yp::ldap'] ~> Class['::yp::bind'] <~ Class['::yp']
#
# @param domain The YP/NIS domain for which to provide maps fetched from LDAP.
# @param conf_file The configuration file, usually `/etc/ypldap.conf`.
# @param directories
# @param interval How often to refresh the maps from LDAP.
# @param maps The list of YP maps to provide based on LDAP searches.
# @param service_name The name of the service managing `ypldap`.
# @param tls_cacert_file
#
# @see puppet_classes::yp ::yp
# @see puppet_classes::yp::bind ::yp::bind
# @see puppet_classes::yp::serv ::yp::serv
# @see puppet_defined_types::yp::ldap::directory ::yp::ldap::directory
class yp::ldap (
  String                          $domain,
  Hash[String, Hash[String, Any]] $directories     = {},
  Stdlib::Absolutepath            $conf_file       = $::yp::params::ldap_conf_file,
  Integer[1]                      $interval        = 60,
  Array[String, 1]                $maps            = $::yp::params::ldap_maps,
  String                          $service_name    = $::yp::params::ldap_service_name,
  Optional[Stdlib::Absolutepath]  $tls_cacert_file = undef,
) inherits yp::params {

  if $facts['os']['family'] != 'OpenBSD' {
    fail("The yp::ldap class is not supported on ${facts['os']['family']} based systems.")
  }

  if defined(Class['yp::serv']) {
    fail('yp::serv and yp::ldap are mutually exclusive.')
  }

  contain yp::ldap::config
  contain yp::ldap::service

  Class['yp::ldap::config'] ~> Class['yp::ldap::service']
}
