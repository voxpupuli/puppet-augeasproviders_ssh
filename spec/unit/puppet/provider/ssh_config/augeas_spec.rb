# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:ssh_config).provider(:augeas)

describe provider_class do
  before do
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(FileTest).to receive(:exist?).with('/etc/ssh/ssh_config').and_return(true)
  end

  context 'with empty file' do
    let(:tmptarget) { aug_fixture('empty') }
    let(:target) { tmptarget.path }

    it 'creates simple new entry' do
      apply!(Puppet::Type.type(:ssh_config).new(
               name: 'ForwardAgent',
               value: 'yes',
               target: target,
               provider: 'augeas'
             ))

      aug_open(target, 'Ssh.lns') do |aug|
        expect(aug.get('Host/ForwardAgent')).to eq('yes')
      end
    end

    it 'creates an array entry for GlobalKnownHostsFile' do
      apply!(Puppet::Type.type(:ssh_config).new(
               name: 'GlobalKnownHostsFile',
               value: ['/etc/ssh/ssh_known_hosts', '/etc/ssh/ssh_known_hosts2'],
               target: target,
               provider: 'augeas'
             ))

      aug_open(target, 'Ssh.lns') do |aug|
        expect(aug.get('Host/GlobalKnownHostsFile/1')).to eq('/etc/ssh/ssh_known_hosts')
        expect(aug.get('Host/GlobalKnownHostsFile/2')).to eq('/etc/ssh/ssh_known_hosts2')
      end
    end

    it 'creates an array entry for SendEnv' do
      apply!(Puppet::Type.type(:ssh_config).new(
               name: 'SendEnv',
               value: %w[LANG LC_TYPE],
               target: target,
               provider: 'augeas'
             ))

      aug_open(target, 'Ssh.lns') do |aug|
        expect(aug.get('Host/SendEnv/1')).to eq('LANG')
        expect(aug.get('Host/SendEnv/2')).to eq('LC_TYPE')
      end
    end

    it 'creates new entry for a host' do
      apply!(Puppet::Type.type(:ssh_config).new(
               name: 'ForwardAgent',
               host: 'example.net',
               value: 'yes',
               target: target,
               provider: 'augeas'
             ))

      aug_open(target, 'Ssh.lns') do |aug|
        expect(aug.get("Host[.='example.net']/ForwardAgent")).to eq('yes')
      end
    end

    it 'creates new comment before entry' do
      apply!(Puppet::Type.type(:ssh_config).new(
               name: 'DenyUsers',
               host: 'example.net',
               value: 'example_user',
               target: target,
               provider: 'augeas',
               comment: 'Deny example_user access'
             ))

      aug_open(target, 'Ssh.lns') do |aug|
        expect(aug.get("Host[.='example.net']/#comment[following-sibling::DenyUsers][last()]")).to eq('DenyUsers: Deny example_user access')
      end
    end

    context 'when declaring two resources with same key' do
      it 'fails with same name' do
        expect do
          apply!(
            Puppet::Type.type(:ssh_config).new(
              name: 'ForwardAgent',
              value: 'no',
              target: target,
              provider: 'augeas'
            ),
            Puppet::Type.type(:ssh_config).new(
              name: 'ForwardAgent',
              host: 'example.net',
              value: 'yes',
              target: target,
              provider: 'augeas'
            )
          )
        end.to raise_error(Puppet::Resource::Catalog::DuplicateResourceError)
      end

      it 'fails with different names, same key and no host' do
        expect do
          apply!(
            Puppet::Type.type(:ssh_config).new(
              name: 'ForwardAgent',
              value: 'no',
              target: target,
              provider: 'augeas'
            ),
            Puppet::Type.type(:ssh_config).new(
              name: 'Example ForwardAgent',
              key: 'ForwardAgent',
              value: 'yes',
              target: target,
              provider: 'augeas'
            )
          )
        end.to raise_error
      end

      it 'does not fail with different names, same key and different hosts' do
        expect do
          apply!(
            Puppet::Type.type(:ssh_config).new(
              name: 'ForwardAgent',
              value: 'no',
              target: target,
              provider: 'augeas'
            ),
            Puppet::Type.type(:ssh_config).new(
              name: 'Example ForwardAgent',
              key: 'ForwardAgent',
              host: 'example.net',
              value: 'yes',
              target: target,
              provider: 'augeas'
            )
          )
        end.not_to raise_error
      end
    end
  end

  context 'with full file' do
    let(:tmptarget) { aug_fixture('full') }
    let(:target) { tmptarget.path }

    it 'lists instances' do
      allow(provider_class).to receive(:target).and_return(target)

      inst = provider_class.instances.map do |p|
        {
          name: p.get(:name),
          ensure: p.get(:ensure),
          value: p.get(:value),
          key: p.get(:key),
          host: p.get(:host),
        }
      end

      expect(inst.size).to eq(5)
      expect(inst[0]).to eq(name: 'SendEnv', ensure: :present, value: ['LANG', 'LC_*'], key: 'SendEnv', host: '*')
      expect(inst[1]).to eq(name: 'SendEnv', ensure: :present, value: ['QUX'], key: 'SendEnv', host: '*')
      expect(inst[2]).to eq(name: 'HashKnownHosts', ensure: :present, value: ['yes'], key: 'HashKnownHosts', host: '*')
      expect(inst[3]).to eq(name: 'GSSAPIAuthentication', ensure: :present, value: ['yes'], key: 'GSSAPIAuthentication', host: '*')
      expect(inst[4]).to eq(name: 'GSSAPIDelegateCredentials', ensure: :present, value: ['no'], key: 'GSSAPIDelegateCredentials', host: '*')
    end

    describe 'when creating settings' do
      it 'adds an entry to a new host' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'ForwardAgent',
                 host: 'example.net',
                 value: 'yes',
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.get("Host[.='example.net']/ForwardAgent")).to eq('yes')
        end
      end

      it 'creates an array entry' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'SendEnv',
                 host: 'example.net',
                 value: ['LC_*', 'LANG'],
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.get("Host[.='example.net']/SendEnv/1")).to eq('LC_*')
          expect(aug.get("Host[.='example.net']/SendEnv/2")).to eq('LANG')
        end
      end

      it 'creates new comment before entry' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'DenyUsers',
                 host: 'example.net',
                 value: 'example_user',
                 target: target,
                 provider: 'augeas',
                 comment: 'Deny example_user access'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.get("Host[.='example.net']/#comment[following-sibling::DenyUsers][last()]")).to eq('DenyUsers: Deny example_user access')
        end
      end
    end

    describe 'when deleting settings' do
      it 'deletes a setting' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'HashKnownHosts',
                 ensure: 'absent',
                 host: '*',
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.match("Host[.='*']/HashKnownHosts").size).to eq(0)
        end
      end

      it 'deletes a comment' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'VisualHostKey',
                 ensure: 'absent',
                 host: '*',
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.match("Host[.='*']/VisualHostKey[preceding-sibling::#comment]").size).to eq(0)
        end
      end
    end

    describe 'when updating settings' do
      it 'replaces a setting' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'HashKnownHosts',
                 host: '*',
                 value: 'no',
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.get("Host[.='*']/HashKnownHosts")).to eq('no')
        end
      end

      it 'replaces the comment' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'HashKnownHosts',
                 host: '*',
                 target: target,
                 provider: 'augeas',
                 comment: 'This is a different comment'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.get("Host[.='*']/#comment[following-sibling::HashKnownHosts][last()]")).to eq('HashKnownHosts: This is a different comment')
        end
      end

      it 'replaces the array setting' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'SendEnv',
                 host: '*',
                 value: %w[foo bar],
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.match("Host[.='*']/SendEnv/*").size).to eq(2)
          expect(aug.get("Host[.='*']/SendEnv/1")).to eq('foo')
          expect(aug.get("Host[.='*']/SendEnv/2")).to eq('bar')
        end
      end

      it 'replaces settings case insensitively' do
        apply!(Puppet::Type.type(:ssh_config).new(
                 name: 'GssaPiaUthentication',
                 value: 'yes',
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.match("Host[.='*']/*[label()=~regexp('GSSAPIAuthentication', 'i')]").size).to eq(1)
          expect(aug.get("Host[.='*']/GSSAPIAuthentication")).to eq('yes')
        end
      end
    end
  end

  context 'with broken file' do
    let(:tmptarget) { aug_fixture('broken') }
    let(:target) { tmptarget.path }

    it 'fails to load' do
      txn = apply(Puppet::Type.type(:ssh_config).new(
                    name: 'ForwardAgent',
                    value: 'yes',
                    target: target,
                    provider: 'augeas'
                  ))

      expect(txn.any_failed?).not_to eq(nil)
      expect(@logs.first.level).to eq(:err)
      expect(@logs.first.message.include?(target)).to eq(true)
    end
  end
end
