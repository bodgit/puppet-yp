require 'spec_helper'

describe 'yp::bind' do

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

      it { should contain_anchor('yp::bind::begin') }
      it { should contain_anchor('yp::bind::end') }
      it { should contain_class('yp::bind') }
      it { should contain_class('yp::bind::install') }
      it { should contain_class('yp::bind::config') }
      it { should contain_class('yp::bind::service') }
      it { should contain_class('yp::params') }

      it { should contain_service('ypbind') }

      case facts[:osfamily]
      when 'OpenBSD'
        it { should contain_augeas('/etc/group/nisdefault') }
        it { should contain_augeas('/etc/master.passwd/nisdefault') }
        it { should contain_file('/etc/yp') }
        it { should contain_exec('pwd_mkdb -p /etc/master.passwd') }
        it { should contain_file('/usr/local/share/augeas/lenses/group.aug') }
        it { should contain_file('/usr/local/share/augeas/lenses/masterpasswd.aug') }
        it { should contain_file('/usr/local/share/augeas/lenses/passwd.aug') }
        it { should have_package_resource_count(0) }
      else
        it { should contain_class('nsswitch') }
        it { should contain_file('/etc/yp.conf') }
        it { should contain_package('ypbind') }
        it { should contain_pam('nis') }
      end
    end
  end
end
