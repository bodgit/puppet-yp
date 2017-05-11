require 'spec_helper'

describe 'yp::ldap' do

  let(:params) do
    {
      :base_dn => 'dc=example,dc=com',
      :domain  => 'example.com',
      :server  => '127.0.0.1'
    }
  end

  context 'on unsupported distributions' do
    let(:facts) do
      {
        :osfamily => 'Unsupported'
      }
    end

    it { expect { should compile }.to raise_error(/not supported on Unsupported/) }
  end

  on_supported_os.each do |os, facts|

    next if os !~ /^openbsd/

    context "on #{os}", :compile do
      let(:facts) do
        facts
      end

      it { should contain_class('yp::ldap') }
      it { should contain_class('yp::ldap::config') }
      it { should contain_class('yp::ldap::service') }
      it { should contain_class('yp::params') }
      it do
        should contain_file('/etc/ypldap.conf').with_content(<<-EOS.gsub(/^ +/, ''))
          # !!! Managed by Puppet !!!

          domain		"example.com"
          interval	60
          provide map	"passwd.byname"
          provide map	"passwd.byuid"
          provide map	"group.byname"
          provide map	"group.bygid"
          provide map	"netid.byname"

          directory "127.0.0.1" {
          	basedn "dc=example,dc=com"

          	passwd filter "(objectClass=posixAccount)"

          	attribute name maps to "uid"
          	fixed attribute passwd "*"
          	attribute uid maps to "uidNumber"
          	attribute gid maps to "gidNumber"
          	attribute gecos maps to "cn"
          	attribute home maps to "homeDirectory"
          	attribute shell maps to "loginShell"
          	fixed attribute change "0"
          	fixed attribute expire "0"
          	fixed attribute class "ldap"

          	group filter "(objectClass=posixGroup)"

          	attribute groupname maps to "cn"
          	fixed attribute grouppasswd "*"
          	attribute groupgid maps to "gidNumber"
          	list groupmembers maps to "memberUid"
          }
        EOS
      end
      it { should contain_service('ypldap') }
    end
  end
end
