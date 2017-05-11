require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.4.0') >= 0
  describe 'test::ldap::attribute', type: :class do
    describe 'accepts an LDAP attribute' do
      [
        'change',
        'class',
        'expire',
        'gecos',
        'gid',
        'groupgid',
        'groupmembers',
        'groupname',
        'grouppasswd',
        'home',
        'name',
        'passwd',
        'shell',
        'uid',
      ].each do |value|
        describe value.inspect do
          let(:params) {{ value: value }}
          it { is_expected.to compile }
        end
      end
    end
    describe 'rejects other values' do
      [
        'invalid',
        123,
      ].each do |value|
        describe value.inspect do
          let(:params) {{ value: value }}
          it {is_expected.to compile.and_raise_error(/parameter 'value' /) }
        end
      end
    end
  end
end
