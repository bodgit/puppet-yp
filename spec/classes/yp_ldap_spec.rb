require 'spec_helper'

describe 'yp::ldap' do
  let(:params) do
    {
      domain: 'example.com',
      directories: {
        'dc=example,dc=com' => {
          'server' => '127.0.0.1',
        },
      },
    }
  end

  context 'on unsupported distributions' do
    let(:facts) do
      {
        osfamily: 'Unsupported',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{not supported on Unsupported}) }
  end

  on_supported_os.each do |os, facts|
    next if os !~ %r{^openbsd}

    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('yp::ldap') }
      it { is_expected.to contain_class('yp::ldap::config') }
      it { is_expected.to contain_class('yp::ldap::service') }
      it { is_expected.to contain_class('yp::params') }
      it { is_expected.to contain_concat('/etc/ypldap.conf') }
      it { is_expected.to contain_concat__fragment('/etc/ypldap.conf global').with_content(<<-EOS.gsub(%r{^ {8}}, '')) }

        domain		"example.com"
        interval	60
        provide map	"passwd.byname"
        provide map	"passwd.byuid"
        provide map	"group.byname"
        provide map	"group.bygid"
        provide map	"netid.byname"
        EOS
      it { is_expected.to contain_concat__fragment('/etc/ypldap.conf dc=example,dc=com').with_content(<<-EOS.gsub(%r{^ {8}}, '')) }

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
      it { is_expected.to contain_service('ypldap') }
      it { is_expected.to contain_yp__ldap__directory('dc=example,dc=com') }
    end
  end
end
