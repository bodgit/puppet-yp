# @!visibility private
class yp::params {

  $bind_service_enable = true
  $bind_service_ensure = 'running'
  $ldap_service_enable = true
  $ldap_service_ensure = 'running'
  $serv_merge_group  = true
  $serv_merge_passwd = true
  $serv_minimum_gid  = 1000
  $serv_minimum_uid  = 1000
  $serv_service_enable = true
  $serv_service_ensure = 'running'
  $yp_dir            = '/var/yp'

  case $::osfamily {
    'OpenBSD': {
      $bind_manage_package         = false
      $bind_package_name           = undef
      $bind_service_name           = 'ypbind'
      $ldap_conf_file              = '/etc/ypldap.conf'
      $ldap_maps                   = [
        'passwd.byname',
        'passwd.byuid',
        'group.byname',
        'group.bygid',
        'netid.byname',
      ]
      $ldap_service_name           = 'ypldap'
      $serv_has_yppasswdd          = false
      $serv_has_ypxfrd             = false
      $serv_manage_package         = false
      $serv_package_name           = undef
      $serv_maps                   = [
        'passwd.byname',
        'passwd.byuid',
        'master.passwd.byname',
        'master.passwd.byuid',
        'group.byname',
        'group.bygid',
        'hosts.byname',
        'hosts.byaddr',
        'ethers.byname',
        'ethers.byaddr',
        'networks.byname',
        'networks.byaddr',
        'rpc.bynumber',
        'services.byname',
        'protocols.byname',
        'protocols.bynumber',
        'netid.byname',
        'netgroup',
        'netgroup.byuser',
        'netgroup.byhost',
        'amd.home',
        'mail.aliases',
        'mail.byaddr',
      ]
      $serv_map_extension          = '.db'
      $serv_yppasswdd_service_name = undef
      $serv_ypserv_service_name    = 'ypserv'
      $serv_ypxfrd_service_name    = undef
    }
    'RedHat': {
      $bind_manage_package         = true
      $bind_package_name           = 'ypbind'
      $bind_service_name           = 'ypbind'
      $ldap_conf_file              = undef
      $ldap_maps                   = undef
      $ldap_service_name           = undef
      $serv_has_yppasswdd          = true
      $serv_has_ypxfrd             = true
      $serv_manage_package         = true
      $serv_maps                   = [
        'passwd.byname',
        'passwd.byuid',
        'group.byname',
        'group.bygid',
        'hosts.byname',
        'hosts.byaddr',
        'rpc.byname',
        'rpc.bynumber',
        'services.byname',
        'services.byservicename',
        'netid.byname',
        'protocols.bynumber',
        'protocols.byname',
        'mail.aliases',
        'netgroup',
        'netgroup.byhost',
        'netgroup.byuser',
        'shadow.byname',
        'publickey.byname',
        'networks.byaddr',
        'networks.byname',
        'ethers.byname',
        'ethers.byaddr',
        'bootparams',
        'printcap',
        'amd.home',
        'auto.master',
        'auto.home',
        'auto.local',
        'passwd.adjunct.byname',
        'timezone.byname',
        'locale.byname',
        'netmasks.byaddr',
      ]
      $serv_map_extension          = undef
      $serv_package_name           = 'ypserv'
      $serv_yppasswdd_service_name = 'yppasswdd'
      $serv_ypserv_service_name    = 'ypserv'
      $serv_ypxfrd_service_name    = 'ypxfrd'
    }
    default: {
      fail("The ${module_name} module is not supported on ${::osfamily} based systems.")
    }
  }
}
