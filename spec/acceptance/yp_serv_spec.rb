require 'spec_helper_acceptance'

describe 'yp::serv' do
  case fact('osfamily')
  when 'OpenBSD'
    group         = 'wheel'
    makedbm       = '/usr/sbin/makedbm'
    maps          = [
      'passwd.byname',
      'passwd.byuid',
      'master.passwd.byname',
      'master.passwd.byuid',
      'group.byname',
      'group.bygid',
      'hosts.byname',
      'hosts.byaddr',
      'networks.byname',
      'networks.byaddr',
      'rpc.bynumber',
      'services.byname',
      'protocols.byname',
      'protocols.bynumber',
      'netid.byname',
      'mail.aliases',
      'mail.byaddr',
    ]
    map_extension = '.db'
    shell         = '/bin/ksh'
    targets       = ['passwd', 'group', 'hosts', 'networks', 'rpc', 'services', 'protocols', 'netid', 'aliases']
  when 'RedHat'
    group         = 'root'
    makedbm       = fact('architecture').eql?('x86_64') ? '/usr/lib64/yp/makedbm' : '/usr/lib/yp/makedbm'
    maps          = [
      'passwd.byname',
      'passwd.byuid',
      'group.bygid',
      'group.byname',
      'hosts.byaddr',
      'hosts.byname',
      'rpc.byname',
      'rpc.bynumber',
      'services.byname',
      'services.byservicename',
      'netid.byname',
      'protocols.byname',
      'protocols.bynumber',
      'mail.aliases',
    ]
    map_extension = ''
    shell         = '/bin/bash'
    targets       = ['passwd', 'group', 'hosts', 'rpc', 'services', 'netid', 'protocols', 'mail']
  end

  it 'works with no errors' do
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

    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes:  true)
  end

  # Delete the user as it should still be present in the YP map(s)
  describe command('userdel bob') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  # Delete the group as it should still be present in the YP map(s)
  describe command('groupdel bob') do
    its(:exit_status) { is_expected.to eq 0 } if fact('osfamily').eql?('OpenBSD')
    its(:exit_status) { is_expected.to eq 8 } if fact('osfamily').eql?('RedHat')
  end

  describe service('ypserv') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe service('yppasswdd'), unless: fact('osfamily').eql?('OpenBSD') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe file('/var/yp') do
    it { is_expected.to be_directory }
    it { is_expected.to be_mode 755 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into group }
  end

  describe file('/var/yp/Makefile') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into group }
    case fact('osfamily')
    when 'OpenBSD'
      its(:content) { is_expected.to match %r{^SUBDIR=example.com$} }
      its(:content) { is_expected.to match %r{^#{targets.join(' ')} :} }
    when 'RedHat'
      its(:content) { is_expected.to match %r{^all:  #{targets.join(' ')}$} }
      its(:content) { is_expected.to match %r{^NOPUSH=true$} }
      its(:content) { is_expected.to match %r{^MINUID=1000$} }
      its(:content) { is_expected.to match %r{^MINGID=1000$} }
      its(:content) { is_expected.to match %r{^MERGE_PASSWD=true$} }
      its(:content) { is_expected.to match %r{^MERGE_GROUP=true$} }
    end
  end

  describe file('/var/yp/example.com') do
    it { is_expected.to be_directory }
    it { is_expected.to be_mode 755 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into group }
  end

  describe file('/var/yp/example.com/Makefile'), if: fact('osfamily').eql?('OpenBSD') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into group }
    its(:content) { is_expected.to match %r{^all: #{targets.join(' ')}$} }
    its(:content) { is_expected.to match %r{^NOPUSH="True"$} }
    its(:content) { is_expected.to match %r{^UNSECURE="True"$} }
    its(:content) { is_expected.to match %r{^MINUID=1000$} }
    its(:content) { is_expected.to match %r{^MINGID=1000$} }
  end

  describe file('/var/yp/ypservers') do
    its(:content) { is_expected.to match %r{^#{fact('hostname')}$} }
  end

  (maps + ['ypservers']).each do |m|
    describe file("/var/yp/example.com/#{m}#{map_extension}") do
      it { is_expected.to be_file }
      it { is_expected.to be_mode 600 }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into group }
      its(:size) { is_expected.to > 0 }
    end
  end

  targets.each do |t|
    describe file("/var/yp/example.com/#{t}.time"), if: fact('osfamily').eql?('OpenBSD') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode 644 }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into group }
      its(:size) { is_expected.to eq 0 }
    end
  end

  describe file('/etc/defaultdomain'), if: fact('osfamily').eql?('OpenBSD') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into group }
    its(:content) { is_expected.to eq "example.com\n" }
  end

  describe file('/etc/sysconfig/network'), if: fact('osfamily').eql?('RedHat') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into group }
    its(:content) { is_expected.to match %r{^NISDOMAIN=example.com$} }
  end

  describe command('domainname') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to eq "example.com\n" }
  end

  describe command("#{makedbm} -u /var/yp/example.com/ypservers") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{^ #{fact('hostname')} \s+ #{fact('hostname')} $}x }
  end

  describe command("#{makedbm} -u /var/yp/example.com/passwd.byname") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{^ bob \s+ bob : [!*]+ : 2001 : 2001 : Bob \s Example : \/home\/bob : #{shell} $}x }
  end

  describe command("#{makedbm} -u /var/yp/example.com/passwd.byuid") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{^ 2001 \s+ bob : [!*]+ : 2001 : 2001 : Bob \s Example : \/home\/bob : #{shell} $}x }
  end

  describe command("#{makedbm} -u /var/yp/example.com/group.bygid") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{^ 2001 \s+ bob : [!*] : 2001 : $}x }
  end

  describe command("#{makedbm} -u /var/yp/example.com/group.byname") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{^ bob \s+ bob : [!*] : 2001 : $}x }
  end

  describe file('/etc/master.passwd'), if: fact('osfamily').eql?('OpenBSD') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 600 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'wheel' }
    its(:content) { is_expected.to match %r{^ \+ : \* :::::::: $}x }
    its(:content) { is_expected.not_to match %r{^ bob :}x }
  end

  describe file('/etc/passwd') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into group }
    its(:content) { is_expected.to match %r{^ \+ : \* :0:0::: $}x } if fact('osfamily').eql?('OpenBSD')
    its(:content) { is_expected.not_to match %r{^ bob :}x }
  end

  describe file('/etc/group') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into group }
    its(:content) { is_expected.to match %r{^ \+ : \* :: $}x } if fact('osfamily').eql?('OpenBSD')
    its(:content) { is_expected.not_to match %r{^ bob :}x }
  end

  case fact('osfamily')
  when 'RedHat'
    describe file('/etc/yp.conf') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode 644 }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      its(:content) { is_expected.to match %r{^ ypserver \s+ 127\.0\.0\.1 $}x }
    end

    describe file('/etc/pam.d/system-auth-ac') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode 644 }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      its(:content) { is_expected.to match %r{^ password \s+ sufficient \s+ pam_unix\.so \s+ md5 \s+ shadow \s+ nis \s+ nullok \s+ try_first_pass \s+ use_authtok $}x }
    end

    describe file('/etc/nsswitch.conf') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode 644 }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      its(:content) { is_expected.to match %r{^ passwd : \s+ files \s+ nis \s+ sss $}x }
      its(:content) { is_expected.to match %r{^ shadow : \s+ files \s+ nis \s+ sss $}x }
      its(:content) { is_expected.to match %r{^ group : \s+ files \s+ nis \s+ sss $}x }
      its(:content) { is_expected.to match %r{^ hosts : \s+ files \s+ nis \s+ dns $}x }
      its(:content) { is_expected.to match %r{^ netgroup : \s+ files \s+ nis \s+ sss $}x }
      its(:content) { is_expected.to match %r{^ automount : \s+ files \s+ nis $}x }
    end
  end

  describe service('ypbind') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe command('rpcinfo -p') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{100004 \s+ 2 \s+ tcp \s+ \d+ \s+ ypserv}x }
    its(:stdout) { is_expected.to match %r{100004 \s+ 2 \s+ udp \s+ \d+ \s+ ypserv}x }
    its(:stdout) { is_expected.to match %r{100007 \s+ 2 \s+ tcp \s+ \d+ \s+ ypbind}x }
    its(:stdout) { is_expected.to match %r{100007 \s+ 2 \s+ udp \s+ \d+ \s+ ypbind}x }
    its(:stdout) { is_expected.to match %r{100009 \s+ 1 \s+ udp \s+ \d+ \s+ yppasswdd}x } unless fact('osfamily').eql?('OpenBSD')
  end

  describe group('bob') do
    it { is_expected.to exist }
    it { is_expected.to have_gid 2001 }
  end

  describe user('bob') do
    it { is_expected.to exist }
    it { is_expected.to belong_to_group 'bob' }
    it { is_expected.to have_uid 2001 }
    it { is_expected.to have_home_directory '/home/bob' }
    it { is_expected.to have_login_shell shell }
  end
end
