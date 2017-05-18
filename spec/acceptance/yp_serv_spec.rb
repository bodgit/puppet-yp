require 'spec_helper_acceptance'

describe 'yp::serv' do

  case fact('osfamily')
  when 'OpenBSD'
    group         = 'wheel'
    makedbm       = '/usr/sbin/makedbm'
    maps          = %w(passwd.byname passwd.byuid master.passwd.byname master.passwd.byuid group.byname group.bygid hosts.byname hosts.byaddr networks.byname networks.byaddr rpc.bynumber services.byname protocols.byname protocols.bynumber netid.byname mail.aliases mail.byaddr)
    map_extension = '.db'
    shell         = '/bin/ksh'
    targets       = %w(passwd group hosts networks rpc services protocols netid aliases)
  when 'RedHat'
    group         = 'root'
    makedbm       = fact('architecture').eql?('x86_64') ? '/usr/lib64/yp/makedbm' : '/usr/lib/yp/makedbm'
    maps          = %w(passwd.byname passwd.byuid group.bygid group.byname hosts.byaddr hosts.byname rpc.byname rpc.bynumber services.byname services.byservicename netid.byname protocols.byname protocols.bynumber mail.aliases)
    map_extension = ''
    shell         = '/bin/bash'
    targets       = %w(passwd group hosts rpc services netid protocols mail)
  end

  it 'should work with no errors' do

    pp = <<-EOS
      include ::portmap

      class { '::yp':
        domain => 'example.com',
      }

      class { '::yp::bind':
        domain  => 'example.com',
        servers => [
          '127.0.0.1',
        ],
      }

      if $::osfamily == 'RedHat' {
        class { '::nsswitch':
          passwd    => ['files', 'nis', 'sss'],
          shadow    => ['files', 'nis', 'sss'],
          group     => ['files', 'nis', 'sss'],
          hosts     => ['files', 'nis', 'dns'],
          netgroup  => ['files', 'nis', 'sss'],
          automount => ['files', 'nis'],
          require   => Class['::yp::bind'],
        }

        pam { 'nis':
          ensure    => present,
          service   => 'system-auth-ac',
          type      => 'password',
          control   => 'sufficient',
          module    => 'pam_unix.so',
          arguments => [
            'md5',
            'shadow',
            'nis',
            'nullok',
            'try_first_pass',
            'use_authtok',
          ],
          require   => Class['::yp::bind'],
        }
      }

      class { '::yp::serv':
        domain => 'example.com',
        maps   => ['#{maps.join("', '")}'],
      }

      Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
      Class['::yp::serv'] ~> Class['::yp::bind'] <- Class['::yp']

      group { 'bob':
        ensure => present,
        gid    => 2001,
      }

      user { 'bob':
        ensure     => present,
        comment    => 'Bob Example',
        gid        => 2001,
        home       => '/home/bob',
        managehome => true,
        shell      => '#{shell}',
        uid        => 2001,
        before     => Class['::yp::serv'],
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  # Delete the user as it should still be present in the YP map(s)
  describe command('userdel bob') do
    its(:exit_status) { should eq 0 }
  end

  # Delete the group as it should still be present in the YP map(s)
  describe command('groupdel bob') do
    its(:exit_status) { should eq 0 } if fact('osfamily').eql?('OpenBSD')
    its(:exit_status) { should eq 8 } if fact('osfamily').eql?('RedHat')
  end

  describe service('ypserv') do
    it { should be_enabled }
    it { should be_running }
  end

  describe service('yppasswdd'), :unless => fact('osfamily').eql?('OpenBSD') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/var/yp') do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
  end

  describe file('/var/yp/Makefile') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    case fact('osfamily')
    when 'OpenBSD'
      its(:content) { should match /^SUBDIR=example.com$/ }
      its(:content) { should match /^#{targets.join(' ')} :/ }
    when 'RedHat'
      its(:content) { should match /^all:  #{targets.join(' ')}$/ }
      its(:content) { should match /^NOPUSH=true$/ }
      its(:content) { should match /^MINUID=1000$/ }
      its(:content) { should match /^MINGID=1000$/ }
      its(:content) { should match /^MERGE_PASSWD=true$/ }
      its(:content) { should match /^MERGE_GROUP=true$/ }
    end
  end

  describe file('/var/yp/example.com') do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
  end

  describe file('/var/yp/example.com/Makefile'), :if => fact('osfamily').eql?('OpenBSD') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) { should match /^all: #{targets.join(' ')}$/ }
    its(:content) { should match /^NOPUSH="True"$/ }
    its(:content) { should match /^UNSECURE="True"$/ }
    its(:content) { should match /^MINUID=1000$/ }
    its(:content) { should match /^MINGID=1000$/ }
  end

  describe file('/var/yp/ypservers') do
    its(:content) { should match /^#{fact('hostname')}$/ }
  end

  (maps + %w(ypservers)).each do |m|
    describe file("/var/yp/example.com/#{m}#{map_extension}") do
      it { should be_file }
      it { should be_mode 600 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into group }
      its(:size) { should > 0 }
    end
  end

  targets.each do |t|
    describe file("/var/yp/example.com/#{t}.time"), :if => fact('osfamily').eql?('OpenBSD') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into group }
      its(:size) { should eq 0 }
    end
  end

  describe file('/etc/defaultdomain'), :if => fact('osfamily').eql?('OpenBSD') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) { should eq "example.com\n" }
  end

  describe file('/etc/sysconfig/network'), :if => fact('osfamily').eql?('RedHat') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) { should match /^NISDOMAIN=example.com$/ }
  end

  describe command('domainname') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should eq "example.com\n" }
  end

  describe command("#{makedbm} -u /var/yp/example.com/ypservers") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^ #{fact('hostname')} \s+ #{fact('hostname')} $/x }
  end

  describe command("#{makedbm} -u /var/yp/example.com/passwd.byname") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^ bob \s+ bob : [!*]+ : 2001 : 2001 : Bob \s Example : \/home\/bob : #{shell} $/x }
  end

  describe command("#{makedbm} -u /var/yp/example.com/passwd.byuid") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^ 2001 \s+ bob : [!*]+ : 2001 : 2001 : Bob \s Example : \/home\/bob : #{shell} $/x }
  end

  describe command("#{makedbm} -u /var/yp/example.com/group.bygid") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^ 2001 \s+ bob : [!*] : 2001 : $/x }
  end

  describe command("#{makedbm} -u /var/yp/example.com/group.byname") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^ bob \s+ bob : [!*] : 2001 : $/x }
  end

  describe file('/etc/master.passwd'), :if => fact('osfamily').eql?('OpenBSD') do
    it { should be_file }
    it { should be_mode 600 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'wheel' }
    its(:content) { should match /^ \+ : \* :::::::: $/x }
    its(:content) { should_not match /^ bob :/x }
  end

  describe file('/etc/passwd') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) { should match /^ \+ : \* :0:0::: $/x } if fact('osfamily').eql?('OpenBSD')
    its(:content) { should_not match /^ bob :/x }
  end

  describe file('/etc/group') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) { should match /^ \+ : \* :: $/x } if fact('osfamily').eql?('OpenBSD')
    its(:content) { should_not match /^ bob :/x }
  end

  case fact('osfamily')
  when 'RedHat'
    describe file('/etc/yp.conf') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should match /^ ypserver \s+ 127\.0\.0\.1 $/x }
    end

    describe file('/etc/pam.d/system-auth-ac') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should match /^ password \s+ sufficient \s+ pam_unix\.so \s+ md5 \s+ shadow \s+ nis \s+ nullok \s+ try_first_pass \s+ use_authtok $/x }
    end

    describe file('/etc/nsswitch.conf') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should match /^ passwd : \s+ files \s+ nis \s+ sss $/x }
      its(:content) { should match /^ shadow : \s+ files \s+ nis \s+ sss $/x }
      its(:content) { should match /^ group : \s+ files \s+ nis \s+ sss $/x }
      its(:content) { should match /^ hosts : \s+ files \s+ nis \s+ dns $/x }
      its(:content) { should match /^ netgroup : \s+ files \s+ nis \s+ sss $/x }
      its(:content) { should match /^ automount : \s+ files \s+ nis $/x }
    end
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
    its(:stdout) { should match /100009 \s+ 1 \s+ udp \s+ \d+ \s+ yppasswdd/x } unless fact('osfamily').eql?('OpenBSD')
  end

  describe group('bob') do
    it { should exist }
    it { should have_gid 2001 }
  end

  describe user('bob') do
    it { should exist }
    it { should belong_to_group 'bob' }
    it { should have_uid 2001 }
    it { should have_home_directory '/home/bob' }
    it { should have_login_shell shell }
  end
end
