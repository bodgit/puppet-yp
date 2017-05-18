# yp

Tested with Travis CI

[![Build Status](https://travis-ci.org/bodgit/puppet-yp.svg?branch=master)](https://travis-ci.org/bodgit/puppet-yp)
[![Coverage Status](https://coveralls.io/repos/bodgit/puppet-yp/badge.svg?branch=master&service=github)](https://coveralls.io/github/bodgit/puppet-yp?branch=master)
[![Puppet Forge](http://img.shields.io/puppetforge/v/bodgit/yp.svg)](https://forge.puppetlabs.com/bodgit/yp)
[![Dependency Status](https://gemnasium.com/bodgit/puppet-yp.svg)](https://gemnasium.com/bodgit/puppet-yp)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with yp](#setup)
    * [What yp affects](#what-yp-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with yp](#beginning-with-yp)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module manages YP/NIS.

This module can configure the YP/NIS domain, manage the `ypbind` daemon to
bind a client to a YP server and create and maintain master & slave YP servers
using `ypserv` and associated daemons. It can also in the special case of
OpenBSD manage the `ypldap` daemon to fetch YP maps from LDAP.

## Setup

### What yp affects

This module will alter the following system files in order to use YP maps:

* On OpenBSD it will add the traditional `+::...` entries to the bottom of the
  `/etc/passwd` and `/etc/group` files.
* On Linux it will manage the `/etc/nsswitch.conf` file and adjust the main PAM
  configuration.

### Setup Requirements

You will need to manage the RPC portmapper by using
[bodgit/portmap](https://forge.puppet.com/bodgit/portmap) or by other means.

### Beginning with yp

Bind a client to a YP domain using three YP servers:

```puppet
include ::portmap

class { '::yp':
  domain => 'example.com',
}

class { '::yp::bind':
  domain  => 'example.com',
  servers => ['192.0.2.1', '192.0.2.2', '192.0.2.3'],
}

Class['::portmap'] ~> Class['::yp::bind'] <~ Class['::yp']
```

## Usage

Create a standalone YP server:

```puppet
include ::portmap

class { '::yp':
  domain => 'example.com',
}

class { '::yp::serv':
  domain => 'example.com',
}

Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
```

Create a master YP server with two additional slaves:

```puppet
include ::portmap

class { '::yp':
  domain => 'example.com',
}

class { '::yp::serv':
  domain => 'example.com',
  maps   => [
    'passwd.byname',
    'passwd.byuid',
    'group.bygid',
    'group.byname',
    'netid.byname',
  ],
  slaves => [
    '192.0.2.2',
    '192.0.2.3',
  ],
}

Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
```

Create a slave YP server pointing at the above master YP server:

```puppet
include ::portmap

class { '::yp':
  domain => 'example.com',
}

class { '::yp::serv':
  domain => 'example.com',
  maps   => [
    'passwd.byname',
    'passwd.byuid',
    'group.bygid',
    'group.byname',
    'netid.byname',
  ],
  master => '192.0.2.1',
}

class { '::yp::bind':
  domain => 'example.com',
}

Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
Class['::yp::serv'] -> Class['::yp::bind'] <~ Class['::yp']
```

For OpenBSD only, set up `ypldap` to create YP maps from an LDAP server and
also bind to it. This is the equivalent to PAM/LDAP on Linux:

```puppet
include ::portmap

class { '::yp::ldap':
  base_dn => 'dc=example,dc=com',
  bind_dn => 'cn=ypldap,dc=example,dc=com',
  bind_pw => 'password',
  domain  => 'example.com',
  server  => '192.0.2.1',
}

class { '::yp':
  domain => 'example.com',
}

class { '::yp::bind':
  domain => 'example.com',
}

Class['::portmap'] ~> Class['::yp::ldap'] ~> Class['::yp::bind'] <~ Class['::yp']
```

## Reference

The reference documentation is generated with
[puppet-strings](https://github.com/puppetlabs/puppet-strings) and the latest
version of the documentation is hosted at
[https://bodgit.github.io/puppet-yp/](https://bodgit.github.io/puppet-yp/).

## Limitations

This module was primarily written with deploying `ypldap` on OpenBSD in mind
however to do that I realised I had classes for everything bar `ypserv` so I
added that and made sure it was portable enough to work on one other OS. It
works however I don't expect many people to still be using traditional YP/NIS.

This module has been built on and tested against Puppet 4.4.0 and higher.

The module has been tested on:

* RedHat Enterprise Linux 7
* OpenBSD 6.0

## Development

The module has both [rspec-puppet](http://rspec-puppet.com) and
[beaker-rspec](https://github.com/puppetlabs/beaker-rspec) tests. Run them
with:

```
$ bundle exec rake test
$ PUPPET_INSTALL_TYPE=agent PUPPET_INSTALL_VERSION=x.y.z bundle exec rake beaker:<nodeset>
```

Please log issues or pull requests at
[github](https://github.com/bodgit/puppet-yp).
