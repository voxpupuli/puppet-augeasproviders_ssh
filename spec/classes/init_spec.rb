# frozen_string_literal: true

require 'spec_helper'
describe 'augeasproviders_ssh' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      context 'with defaults for all parameters' do
        it {
          is_expected.to compile
          is_expected.to have_resource_count(0)
        }
      end

      context 'with all parameters set' do
        let(:params) do
          {
            sshd_configs: {
              AllowAgentForwarding: {
                ensure: 'present',
                value: 'yes',
              },
              PermitRootLogin: {
                ensure: 'present',
                value:  'yes',
              },
            },
            ssh_configs: {
              AddKeysToAgent: {
                ensure: 'present',
                value: 'yes',
              },
            },
            sshd_config_matches: {
              'Host *.example.net': {
                ensure: 'present',
              },
            },
            sshd_config_subsystems: {
              sftp: {
                ensure: 'present',
                command: '/usr/lib/openssh/sftp-server',
              },
            },
          }
        end

        it {
          is_expected.to compile
          is_expected.to contain_sshd_config('AllowAgentForwarding')
          is_expected.to contain_sshd_config('PermitRootLogin')
          is_expected.to contain_ssh_config('AddKeysToAgent')
          is_expected.to contain_sshd_config_match('Host *.example.net')
          is_expected.to contain_sshd_config_subsystem('sftp')
          is_expected.to have_resource_count(5)
        }
      end
    end
  end
end
