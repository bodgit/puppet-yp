require 'spec_helper'

describe 'yp::ldap::directory' do
  let(:pre_condition) do
    'class { "::yp::ldap": domain => "example.com" }'
  end

  let(:title) do
    'dc=example,dc=com'
  end

  let(:params) do
    {
      'server' => '127.0.0.1',
    }
  end

  on_supported_os.each do |os, facts|
    next if os !~ %r{^openbsd}

    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

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
      it { is_expected.to contain_yp__ldap__directory('dc=example,dc=com') }
    end
  end
end
