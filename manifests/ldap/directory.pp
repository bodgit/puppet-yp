# Define an LDAP directory for `ypldap` to poll.
#
# @example Define a directory
#   ::yp::ldap::directory { 'dc=example,dc=com':
#     server  => '192.0.2.1',
#     bind_dn => 'cn=ypldap,dc=example,dc=com',
#     bind_pw => 'secret',
#   }
#
# @param base_dn The base DN from which to perform all LDAP queries.
# @param server The LDAP server to use.
# @param bind_dn The DN to use to bind to the LDAP server.
# @param bind_pw The password to use when binding to the LDAP server.
# @param fixed_attributes A hash of YP map attributes that should not be looked
#   up from LDAP, but hardcoded to a particular value.
# @param group_dn The base DN from which to perform group queries, if different
#   from `base_dn`.
# @param group_filter The LDAP search filter to use when searching for groups.
# @param ldap_attributes A hash of YP map attributes that should be looked up
#   from regular LDAP attributes.
# @param list_attributes A hash of YP map attributes that should be looked up
#   from regular LDAP attributes but in the case of multiple values should be
#   joined together with `,`.
# @param mode
# @param port
# @param user_filter The LDAP search filter to use when searching for users.
#
# @see puppet_classes::yp::ldap ::yp::ldap
#
# @since 3.0.0
define yp::ldap::directory (
  Bodgitlib::Host                   $server,
  Bodgitlib::LDAP::DN               $base_dn          = $title,
  Optional[Bodgitlib::LDAP::DN]     $bind_dn          = undef,
  Optional[String]                  $bind_pw          = undef,
  Hash[YP::LDAP::Attribute, String] $fixed_attributes = {
    'passwd'      => '*',
    'change'      => '0',
    'expire'      => '0',
    'class'       => 'ldap',
    'grouppasswd' => '*',
  },
  Optional[Bodgitlib::LDAP::DN]     $group_dn         = undef,
  Bodgitlib::LDAP::Filter           $group_filter     = '(objectClass=posixGroup)',
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
  Optional[Enum['tls', 'ldaps']]    $mode             = undef,
  Optional[Bodgitlib::Port]         $port             = undef,
  Bodgitlib::LDAP::Filter           $user_filter      = '(objectClass=posixAccount)',
) {

  if ! defined(Class['yp::ldap']) {
    fail('You must include the yp::ldap base class before using any yp::ldap defined resources')
  }

  ::concat::fragment { "${::yp::ldap::conf_file} ${base_dn}":
    order   => '10',
    content => template("${module_name}/ypldap.conf.directory.erb"),
    target  => $::yp::ldap::conf_file,
  }
}
