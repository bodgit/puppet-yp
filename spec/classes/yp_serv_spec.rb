require 'spec_helper'

describe 'yp::serv' do

  let(:params) do
    {
      :domain => 'example.com',
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
        facts.merge(
          {
            :concat_basedir => '/tmp'
          }
        )
      end

      it { should contain_class('yp::serv') }
      it { should contain_class('yp::serv::config') }
      it { should contain_class('yp::serv::install') }
      it { should contain_class('yp::serv::service') }
      it { should contain_class('yp::params') }

      it { should contain_exec("awk '{ if ($1 != \"\" && $1 !~ \"#\") print $0\"\\t\"$0 }' /var/yp/ypservers | makedbm - /var/yp/example.com/ypservers") }
      it { should contain_file('/var/yp/ypservers') }
      it { should contain_file('/var/yp/example.com') }
      it { should contain_service('ypserv') }

      case facts[:osfamily]
      when 'OpenBSD'
        it { should have_package_resource_count(0) }

        {
          'aliases'   => ['mail.aliases', 'mail.byaddr'],
          'amd.home'  => ['amd.home'],
          'ethers'    => ['ethers.byaddr', 'ethers.byname'],
          'group'     => ['group.bygid', 'group.byname'],
          'hosts'     => ['hosts.byaddr', 'hosts.byname'],
          'netgroup'  => ['netgroup', 'netgroup.byhost', 'netgroup.byuser'],
          'netid'     => ['netid.byname'],
          'networks'  => ['networks.byaddr', 'networks.byname'],
          'passwd'    => ['passwd.byname', 'passwd.byuid', 'master.passwd.byname', 'master.passwd.byuid'],
          'protocols' => ['protocols.byname', 'protocols.bynumber'],
          'rpc'       => ['rpc.bynumber'],
          'services'  => ['services.byname'],
        }.each do |k, v|
          v.each do |m|
            it { should contain_yp__serv__map(m) }
          end
          it { should contain_exec("make #{k}") }
        end
        it { should contain_file('/var/yp/Makefile') }
        it { should contain_file('/var/yp/example.com/Makefile') }
      when 'RedHat'
        {
          'amd.home'       => ['amd.home'],
          'auto.home'      => ['auto.home'],
          'auto.local'     => ['auto.local'],
          'auto.master'    => ['auto.master'],
          'bootparams'     => ['bootparams'],
          'ethers'         => ['ethers.byaddr', 'ethers.byname'],
          'group'          => ['group.bygid', 'group.byname'],
          'hosts'          => ['hosts.byaddr', 'hosts.byname'],
          'locale'         => ['locale.byname'],
          'mail'           => ['mail.aliases'],
          'netgrp'         => ['netgroup', 'netgroup.byhost', 'netgroup.byuser'],
          'netid'          => ['netid.byname'],
          'netmasks'       => ['netmasks.byaddr'],
          'networks'       => ['networks.byaddr', 'networks.byname'],
          'passwd'         => ['passwd.byname', 'passwd.byuid'],
          'passwd.adjunct' => ['passwd.adjunct.byname'],
          'printcap'       => ['printcap'],
          'protocols'      => ['protocols.byname', 'protocols.bynumber'],
          'publickey'      => ['publickey.byname'],
          'rpc'            => ['rpc.byname', 'rpc.bynumber'],
          'services'       => ['services.byname', 'services.byservicename'],
          'shadow'         => ['shadow.byname'],
          'timezone'       => ['timezone.byname'],
        }.each do |k, v|
          v.each do |m|
            it { should contain_yp__serv__map(m) }
          end
          it { should contain_exec("make -f ../Makefile #{k}") }
        end
        it { should contain_package('ypserv') }
        it { should contain_service('yppasswdd') }
        it { should contain_service('ypxfrd') }
      else
      end
    end
  end
end
