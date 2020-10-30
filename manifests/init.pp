# Class for configuring the YP/NIS domain.
#
# @example Declaring the class
#   class { 'yp':
#     domain => 'example.com',
#   }
#
# @param domain The YP/NIS domain.
# @param yp_dir The base YP directory, usually `/var/yp`.
#
# @see puppet_classes::yp::bind yp::bind
# @see puppet_classes::yp::serv yp::serv
# @see puppet_classes::yp::ldap yp::ldap
class yp (
  String               $domain,
  Stdlib::Absolutepath $yp_dir = $yp::params::yp_dir,
) inherits yp::params {

  contain yp::config
}
