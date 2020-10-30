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

    it { is_expected.to compile.with_all_deps.and_raise_error(%r{not supported on Unsupported}) }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}", :compile do
      let(:facts) do
        facts.merge({
          :augeasversion => '1.3.0',
        })
      end

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
        it { should contain_file('/etc/yp.conf') }
        it { should contain_package('ypbind') }
      end
    end
  end
end
