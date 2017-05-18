require 'spec_helper_acceptance'

describe 'yp::ldap' do

  pp = <<-EOS
    Package {
      source => $::osfamily ? {
        # $::architecture fact has gone missing on facter 3.x package currently installed
        'OpenBSD' => "http://ftp.openbsd.org/pub/OpenBSD/${::operatingsystemrelease}/packages/amd64/",
        default   => undef,
      },
    }

    include ::openldap
    class { '::openldap::server':
      root_dn       => 'cn=Manager,dc=example,dc=com',
      root_password => 'secret',
      suffix        => 'dc=example,dc=com',
      access        => [
        [
          {
            'attrs' => ['userPassword'],
          },
          [
            {
              'who'    => ['self'],
              'access' => '=xw',
            },
            {
              'who'    => ['anonymous'],
              'access' => 'auth',
            },
          ],
        ],
        [
          {
            'dn' => '*',
          },
          [
            {
              'who'    => ['dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"'],
              'access' => 'manage',
            },
            {
              'who'    => ['users'],
              'access' => 'read',
            },
          ],
        ],
      ],
    }

    ::openldap::server::schema { 'cosine':
      ensure => present,
    }
    ::openldap::server::schema { 'inetorgperson':
      ensure  => present,
      require => ::Openldap::Server::Schema['cosine'],
    }
    ::openldap::server::schema { 'nis':
      ensure  => present,
      require => ::Openldap::Server::Schema['inetorgperson'],
    }

    include ::portmap

    class { '::yp::ldap':
      base_dn  => 'dc=example,dc=com',
      bind_dn  => 'cn=ypldap,dc=example,dc=com',
      bind_pw  => 'password',
      domain   => 'example.com',
      interval => 1,
      server   => '127.0.0.1',
      require  => Class['::openldap::server'],
    }

    class { '::yp':
      domain => 'example.com',
    }

    class { '::yp::bind':
      domain => 'example.com',
    }

    Class['::portmap'] ~> Class['::yp::ldap'] ~> Class['::yp::bind'] <~ Class['::yp']
  EOS

  case fact('osfamily')
  when 'OpenBSD'
    it 'should work with no errors' do
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    describe command('ldapadd -Y EXTERNAL -H ldapi:/// -f /root/example.ldif') do
      its(:exit_status) { should eq 0 }
    end

    # A small sleep so ypldap has chance to pick up the LDAP import
    describe command('sleep 5') do
      its(:exit_status) { should eq 0 }
    end

    describe file('/etc/ypldap.conf') do
      it { should be_file }
      it { should be_mode 640 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      #its(:content) { should eq ... }
    end

    describe service('ypldap') do
      it { should be_running }
    end

    describe file('/etc/master.passwd') do
      it { should be_file }
      it { should be_mode 600 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should match /^ \+ : \* :::::::: $/x }
      its(:content) { should_not match /^ alice :/x }
    end

    describe file('/etc/passwd') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should match /^ \+ : \* :0:0::: $/x }
      its(:content) { should_not match /^ alice :/x }
    end

    describe file('/etc/group') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should match /^ \+ : \* :: $/x }
      its(:content) { should_not match /^ alice :/x }
    end

    describe file('/etc/defaultdomain') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should eq "example.com\n" }
    end

    describe command('domainname') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should eq "example.com\n" }
    end

    describe service('ypbind') do
      it { should be_enabled }
      it { should be_running }
    end

    describe command('rpcinfo -p') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /100004 \s+ 2 \s+ tcp \s+ \d+ \s+ ypserv/x }
      its(:stdout) { should match /100004 \s+ 2 \s+ udp \s+ \d+ \s+ ypserv/x }
      its(:stdout) { should match /100007 \s+ 2 \s+ tcp \s+ \d+ \s+ ypbind/x }
      its(:stdout) { should match /100007 \s+ 2 \s+ udp \s+ \d+ \s+ ypbind/x }
    end

    describe user('alice') do
      it { should exist }
      it { should belong_to_primary_group 'alice' }
      it { should have_uid 2000 }
      it { should have_home_directory '/home/alice' }
      it { should have_login_shell '/bin/bash' }
    end

    describe group('alice') do
      it { should exist }
      it { should have_gid 2000 }
    end
  else
    it 'should not work' do
      apply_manifest(pp, :expect_failures => true)
    end
  end
end
