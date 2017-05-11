# @!visibility private
class yp::ldap::config {

  $base_dn          = $::yp::ldap::base_dn
  $bind_dn          = $::yp::ldap::bind_dn
  $bind_pw          = $::yp::ldap::bind_pw
  $domain           = $::yp::ldap::domain
  $fixed_attributes = $::yp::ldap::fixed_attributes
  $group_dn         = $::yp::ldap::group_dn
  $group_filter     = $::yp::ldap::group_filter
  $interval         = $::yp::ldap::interval
  $ldap_attributes  = $::yp::ldap::ldap_attributes
  $list_attributes  = $::yp::ldap::list_attributes
  $maps             = $::yp::ldap::maps
  $server           = $::yp::ldap::server
  $user_filter      = $::yp::ldap::user_filter

  file { $::yp::ldap::conf_file:
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0640',
    content => template("${module_name}/ypldap.conf.erb"),
  }
}
