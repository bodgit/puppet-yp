# Class for installing and managing `ypserv` daemon.
#
# @example Create a master YP server with two additional slaves
#   include ::portmap
#
#   class { '::yp':
#     domain => 'example.com',
#   }
#
#   class { '::yp::serv':
#     domain => 'example.com',
#     maps   => [
#       'passwd.byname',
#       'passwd.byuid',
#       'group.bygid',
#       'group.byname',
#       'netid.byname',
#     ],
#     slaves => [
#       '192.0.2.2',
#       '192.0.2.3',
#     ],
#   }
#
#   Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
#
# @example Create a slave YP server pointing at the above master YP server
#   include ::portmap
#
#   class { '::yp':
#     domain => 'example.com',
#   }
#
#   class { '::yp::serv':
#     domain => 'example.com',
#     maps   => [
#       'passwd.byname',
#       'passwd.byuid',
#       'group.bygid',
#       'group.byname',
#       'netid.byname',
#     ],
#     master => '192.0.2.1',
#   }
#
#   class { '::yp::bind':
#     domain => 'example.com',
#   }
#
#   Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
#   Class['::yp::serv'] ~> Class['::yp::bind'] <- Class['::yp']
#
# @param domain The YP/NIS domain.
# @param has_yppasswdd Does this platform provide `yppasswdd` daemon for
#   changing passwords.
# @param has_ypxfrd Does this platform provide a `ypxfrd`  daemon to help map
#   transfers.
# @param manage_package Whether to manage a package or not. Some operating
#   systems have `ypserv` as part of the base system.
# @param maps The YP maps to build. The default is build all supported maps
#   which often includes some esoteric ones.
# @param map_extension The file extension added to compiled maps, often `.db`.
# @param master If this is a slave YP server, the IP address of the master.
# @param merge_group Whether to merge group passwords into the group maps.
# @param merge_passwd Whether to merge user passwords into the passwd maps, on
#   some platforms this allows a separate `shadow.byname` map to be created.
# @param minimum_gid Any GID lower than this will not be included in the group
#   maps.
# @param minimum_uid Any UID lower than this will not be included in the passwd
#   maps.
# @param package_name The name of the package to install that provides the
#   `ypserv` daemon.
# @param yppasswdd_service_name The name of the service managing `yppasswdd`.
# @param ypserv_service_name The name of the service managing `ypserv`.
# @param ypxfrd_service_name The name of the service managing `ypxfrd`.
# @param slaves If this is a master YP server, specify the slaves which will be
#   notified when a map is updated.
# @param yp_dir The base YP directory, usually `/var/yp`.
#
# @see puppet_classes::yp ::yp
# @see puppet_classes::yp::bind ::yp::bind
# @see puppet_classes::yp::ldap ::yp::ldap
class yp::serv (
  String                                            $domain,
  Boolean                                           $has_yppasswdd          = $::yp::params::serv_has_yppasswdd,
  Boolean                                           $has_ypxfrd             = $::yp::params::serv_has_ypxfrd,
  Boolean                                           $manage_package         = $::yp::params::serv_manage_package,
  Array[String, 1]                                  $maps                   = $::yp::params::serv_maps,
  Optional[String]                                  $map_extension          = $::yp::params::serv_map_extension,
  Optional[Stdlib::IP::Address::NoSubnet]           $master                 = undef,
  Boolean                                           $merge_group            = $::yp::params::serv_merge_group,
  Boolean                                           $merge_passwd           = $::yp::params::serv_merge_passwd,
  Integer[0]                                        $minimum_gid            = $::yp::params::serv_minimum_gid,
  Integer[0]                                        $minimum_uid            = $::yp::params::serv_minimum_uid,
  Optional[String]                                  $package_name           = $::yp::params::serv_package_name,
  Optional[String]                                  $yppasswdd_service_name = $::yp::params::serv_yppasswdd_service_name,
  String                                            $ypserv_service_name    = $::yp::params::serv_ypserv_service_name,
  Optional[String]                                  $ypxfrd_service_name    = $::yp::params::serv_ypxfrd_service_name,
  Optional[Array[Stdlib::IP::Address::NoSubnet, 1]] $slaves                 = undef,
  Stdlib::Absolutepath                              $yp_dir                 = $::yp::params::yp_dir,
) inherits yp::params {

  if defined(Class['yp::ldap']) {
    fail('yp::ldap and yp::serv are mutually exclusive.')
  }

  contain yp::serv::install
  contain yp::serv::config
  contain yp::serv::service

  Class['yp::serv::install'] -> Class['yp::serv::config']
    ~> Class['yp::serv::service']
}
