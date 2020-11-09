require 'spec_helper'

describe 'yp::bind' do
  let(:params) do
    {
      domain: 'example.com',
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
    context "on #{os}" do
      let(:facts) do
        facts.merge(augeasversion: '1.3.0')
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('yp::bind') }
      it { is_expected.to contain_class('yp::bind::install') }
      it { is_expected.to contain_class('yp::bind::config') }
      it { is_expected.to contain_class('yp::bind::service') }
      it { is_expected.to contain_class('yp::params') }

      it { is_expected.to contain_service('ypbind') }

      case facts[:osfamily]
      when 'OpenBSD'
        it { is_expected.to contain_augeas('/etc/group/nisdefault') }
        it { is_expected.to contain_augeas('/etc/master.passwd/nisdefault') }
        it { is_expected.to contain_file('/etc/yp') }
        it { is_expected.to contain_exec('pwd_mkdb -p /etc/master.passwd') }
        it { is_expected.to contain_file('/usr/local/share/augeas/lenses/group.aug') }
        it { is_expected.to contain_file('/usr/local/share/augeas/lenses/masterpasswd.aug') }
        it { is_expected.to contain_file('/usr/local/share/augeas/lenses/passwd.aug') }
        it { is_expected.to have_package_resource_count(0) }
      else
        it { is_expected.to contain_file('/etc/yp.conf') }
        it { is_expected.to contain_package('ypbind') }
      end
    end
  end
end
