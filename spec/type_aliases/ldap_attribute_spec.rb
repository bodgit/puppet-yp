require 'spec_helper'

describe 'YP::LDAP::Attribute' do
  it { is_expected.to allow_values('change', 'class', 'expire', 'gecos', 'gid', 'groupgid', 'groupmembers', 'groupname', 'grouppasswd', 'home', 'name', 'passwd', 'shell', 'uid') }
  it { is_expected.not_to allow_values('invalid', 123) }
end
