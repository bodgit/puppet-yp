require 'spec_helper'

describe 'yp' do
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
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('yp') }
      it { is_expected.to contain_class('yp::config') }
      it { is_expected.to contain_class('yp::params') }

      it { is_expected.to contain_exec('domainname example.com') }
      it { is_expected.to contain_file('/var/yp') }

      case facts[:osfamily]
      when 'OpenBSD'
        it { is_expected.to contain_file('/etc/defaultdomain') }
      when 'RedHat'
        it { is_expected.to contain_augeas('/etc/sysconfig/network/NISDOMAIN') }
      end
    end
  end
end
