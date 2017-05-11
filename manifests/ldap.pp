# Class for installing and managing `ypldap` daemon.
#
# This is for OpenBSD only and is the equivalent of PAM/LDAP on Linux.
#
# @example Declaring the class
#   include ::portmap
#
#   class { '::yp::ldap':
#     base_dn => 'dc=example,dc=com',
#     bind_dn => 'cn=ypldap,dc=example,dc=com',
#     bind_pw => 'secret',
#     domain  => 'example.com',
#     server  => '192.0.2.1',
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
# @param base_dn The base DN from which to perform all LDAP queries.
# @param domain The YP/NIS domain for which to provide maps fetched from LDAP.
# @param server The LDAP server to use.
# @param bind_dn The DN to use to bind to the LDAP server.
# @param bind_pw The password to use when binding to the LDAP server.
# @param conf_file The configuration file, usually `/etc/ypldap.conf`.
# @param fixed_attributes A hash of YP map attributes that should not be looked
#   up from LDAP, but hardcoded to a particular value.
# @param group_dn The base DN from which to perform group queries, if different
#   from `base_dn`.
# @param group_filter The LDAP search filter to use when searching for groups.
# @param interval How often to refresh the maps from LDAP.
# @param ldap_attributes A hash of YP map attributes that should be looked up
#   from regular LDAP attributes.
# @param list_attributes A hash of YP map attributes that should be looked up
#   from regular LDAP attributes but in the case of multiple values should be
#   joined together with `,`.
# @param maps The list of YP maps to provide based on LDAP searches.
# @param service_name The name of the service managing `ypldap`.
# @param user_filter The LDAP search filter to use when searching for users.
#
# @see puppet_classes::yp ::yp
# @see puppet_classes::yp::bind ::yp::bind
# @see puppet_classes::yp::serv ::yp::serv
class yp::ldap (
  Bodgitlib::LDAP::DN               $base_dn,
  Bodgitlib::Domain                 $domain,
  Bodgitlib::Host                   $server,
  Optional[Bodgitlib::LDAP::DN]     $bind_dn          = undef,
  Optional[String]                  $bind_pw          = undef,
  Stdlib::Absolutepath              $conf_file        = $::yp::params::ldap_conf_file,
  Hash[YP::LDAP::Attribute, String] $fixed_attributes = {
    'passwd'      => '*',
    'change'      => '0',
    'expire'      => '0',
    'class'       => 'ldap',
    'grouppasswd' => '*',
  },
  Optional[Bodgitlib::LDAP::DN]     $group_dn         = undef,
  Bodgitlib::LDAP::Filter           $group_filter     = '(objectClass=posixGroup)',
  Integer[1]                        $interval         = 60,
  Hash[YP::LDAP::Attribute, String] $ldap_attributes  = {
    'name'      => 'uid',
    'uid'       => 'uidNumber',
    'gid'       => 'gidNumber',
    'gecos'     => 'cn',
    'home'      => 'homeDirectory',
    'shell'     => 'loginShell',
    'groupname' => 'cn',
    'groupgid'  => 'gidNumber',
  },
  Hash[YP::LDAP::Attribute, String] $list_attributes  = {
    'groupmembers' => 'memberUid',
  },
  Array[String, 1]                  $maps             = $::yp::params::ldap_maps,
  String                            $service_name     = $::yp::params::ldap_service_name,
  Bodgitlib::LDAP::Filter           $user_filter      = '(objectClass=posixAccount)',
) inherits ::yp::params {

  if $::osfamily != 'OpenBSD' {
    fail("The yp::ldap class is not supported on ${::osfamily} based systems.")
  }

  if defined(Class['::yp::serv']) {
    fail('yp::serv and yp::ldap are mutually exclusive.')
  }

  contain ::yp::ldap::config
  contain ::yp::ldap::service

  Class['::yp::ldap::config'] ~> Class['::yp::ldap::service']
}
