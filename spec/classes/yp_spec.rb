require 'spec_helper'

describe 'yp' do

  let(:params) do
    {
      :domain => 'example.com'
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
    context "on #{os}", :compile do
      let(:facts) do
        facts
      end

      it { should contain_class('yp') }
      it { should contain_class('yp::config') }
      it { should contain_class('yp::params') }

      it { should contain_exec('domainname example.com') }
      it { should contain_file('/var/yp') }

      case facts[:osfamily]
      when 'OpenBSD'
        it { should contain_file('/etc/defaultdomain') }
      when 'RedHat'
        it { should contain_augeas('/etc/sysconfig/network/NISDOMAIN') }
      end
    end
  end
end
