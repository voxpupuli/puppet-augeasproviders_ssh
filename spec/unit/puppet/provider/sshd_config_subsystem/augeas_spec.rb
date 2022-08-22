#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:sshd_config_subsystem).provider(:augeas)

describe provider_class do
  before :each do
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(FileTest).to receive(:exist?).with('/etc/ssh/ssh_config').and_return(true)
  end

  context 'with empty file' do
    let(:tmptarget) { aug_fixture('empty') }
    let(:target) { tmptarget.path }

    it 'creates simple new entry' do
      apply!(Puppet::Type.type(:sshd_config_subsystem).new(
               name: 'sftp',
               command: '/usr/lib/openssh/sftp-server',
               target: target,
               provider: 'augeas',
      ))

      aug_open(target, 'Sshd.lns') do |aug|
        expect(aug.get('Subsystem/sftp')).to eq('/usr/lib/openssh/sftp-server')
      end
    end

    it 'creates new comment before entry' do
      apply!(Puppet::Type.type(:sshd_config_subsystem).new(
               name: 'sftp',
               command: '/usr/lib/openssh/sftp-server',
               target: target,
               provider: 'augeas',
               comment: 'Use the external subsystem',
      ))

      aug_open(target, 'Sshd.lns') do |aug|
        expect(aug.get('#comment[following-sibling::Subsystem[sftp]]')).to eq('sftp: Use the external subsystem')
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
          command: p.get(:command),
        }
      end

      expect(inst.size).to eq(1)
      expect(inst[0]).to eq(name: 'sftp', ensure: :present,
                            command: '/usr/libexec/openssh/sftp-server')
    end

    describe 'when creating settings' do
      it 'adds it before Match block' do
        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
                 name: 'mysub',
                 command: '/bin/bash',
                 target: target,
                 provider: 'augeas',
        ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.get('Subsystem/mysub')).to eq('/bin/bash')
        end
      end

      it 'creates new comment before entry' do
        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
                 name: 'sftp2',
                 command: '/usr/lib/openssh/sftp-server2',
                 target: target,
                 provider: 'augeas',
                 comment: 'Use the external subsystem',
        ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.get('#comment[following-sibling::Subsystem[sftp2]][last()]')).to eq('sftp2: Use the external subsystem')
        end
      end
    end

    describe 'when deleting settings' do
      it 'deletes a setting' do
        expr = 'Subsystem/sftp'
        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.match(expr)).not_to eq([])
        end

        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
                 name: 'sftp',
                 ensure: 'absent',
                 target: target,
                 provider: 'augeas',
        ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.match(expr)).to eq([])
        end
      end

      it 'deletes a comment' do
        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
                 name: 'sftp',
                 command: '/usr/lib/openssh/sftp-server',
                 target: target,
                 provider: 'augeas',
        ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.get('#comment[following-sibling::Subsystem[sftp][1]]')).to eq(nil)
        end
      end
    end

    describe 'when updating settings' do
      it 'replaces a setting' do
        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
                 name: 'sftp',
                 command: '/bin/bash',
                 target: target,
                 provider: 'augeas',
        ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.get('Subsystem/sftp')).to eq('/bin/bash')
        end
      end

      it 'replaces the comment' do
        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
                 name: 'sftp',
                 command: '/usr/lib/openssh/sftp-server',
                 target: target,
                 provider: 'augeas',
                 comment: 'A different comment',
        ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.get('#comment[following-sibling::Subsystem[sftp]][last()]')).to eq('sftp: A different comment')
        end
      end
    end
  end

  context 'with broken file' do
    let(:tmptarget) { aug_fixture('broken') }
    let(:target) { tmptarget.path }

    it 'fails to load' do
      txn = apply(Puppet::Type.type(:sshd_config_subsystem).new(
                    name: 'sftp',
                    command: '/bin/bash',
                    target: target,
                    provider: 'augeas',
      ))

      # rubocop:disable RSpec/InstanceVariable
      expect(txn.any_failed?).not_to eq(nil)
      expect(@logs.first.level).to eq(:err)
      expect(@logs.first.message.include?(target)).to eq(true)
    end
  end
end
