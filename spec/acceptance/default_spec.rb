require 'spec_helper_acceptance'

test_name 'ssh provider test'

describe 'ssh provider test' do
  hosts.each do |host|
    context "on host #{host}" do
      context 'AllowAgentForwarding' do
        let(:manifest) {<<-EOM
            sshd_config { 'AllowAgentForwarding':
              ensure => 'present',
              value  => 'yes'
            }
          EOM
        }

        it 'should be enabled' do
          apply_manifest_on(host, manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(host, manifest, :catch_changes => true)
        end
      end

      context 'should set AddressFamily' do
        let(:manifest) {<<-EOM
            sshd_config { 'AddressFamily':
              ensure => 'present',
              value  => 'any'
            }
          EOM
        }

        it 'to any' do
          apply_manifest_on(host, manifest, :catch_failures => true)
        end
      end
    end
  end
end
