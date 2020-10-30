require 'spec_helper'

describe 'yp::map_to_make_target' do

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      case facts[:osfamily]
      when 'RedHat'
        map     = 'mail.aliases'
        maps    = %w(passwd.byname passwd.byuid group.byname group.bygid hosts.byname hosts.byaddr rpc.byname rpc.bynumber services.byname services.byservicename netid.byname protocols.bynumber protocols.byname mail.aliases netgroup netgroup.byhost netgroup.byuser shadow.byname publickey.byname networks.byaddr networks.byname ethers.byname ethers.byaddr bootparams printcap amd.home auto.master auto.home auto.local passwd.adjunct.byname timezone.byname locale.byname netmasks.byaddr)
        target  = 'mail'
        targets = %w(passwd group hosts rpc services netid protocols mail netgrp shadow publickey networks ethers bootparams printcap amd.home auto.master auto.home auto.local passwd.adjunct timezone locale netmasks)
      when 'OpenBSD'
        map     = 'mail.aliases'
        maps    = %w(passwd.byname passwd.byuid master.passwd.byname master.passwd.byuid group.byname group.bygid hosts.byname hosts.byaddr ethers.byname ethers.byaddr networks.byname networks.byaddr rpc.bynumber services.byname protocols.byname protocols.bynumber netid.byname netgroup netgroup.byuser netgroup.byhost amd.home mail.aliases mail.byaddr)
        target  = 'aliases'
        targets = %w(passwd group hosts ethers networks rpc services protocols netid netgroup amd.home aliases)

      end

      it { should run.with_params(map).and_return(target) }
      it { should run.with_params(maps).and_return(targets) }
      it { is_expected.to run.with_params({}).and_raise_error(%r{parameter 'maps' }) }
    end
  end
end
