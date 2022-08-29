# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:sshd_config_match).provider(:augeas)

describe provider_class do
  before do
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(FileTest).to receive(:exist?).with('/etc/ssh/ssh_config').and_return(true)
  end

  context 'with empty file' do
    let(:tmptarget) { aug_fixture('empty') }
    let(:target) { tmptarget.path }

    it 'creates simple new entry' do
      apply!(Puppet::Type.type(:sshd_config_match).new(
               name: 'Host foo',
               target: target,
               ensure: :present,
               provider: 'augeas'
             ))

      aug_open(target, 'Sshd.lns') do |aug|
        expect(aug.get('Match/Condition/Host')).to eq('foo')
      end
    end

    it 'creates new comment before entry' do
      apply!(Puppet::Type.type(:sshd_config_match).new(
               name: 'Host foo',
               target: target,
               ensure: :present,
               comment: 'manage host foo',
               provider: 'augeas'
             ))

      aug_open(target, 'Sshd.lns') do |aug|
        expect(aug.get('Match[Condition/Host]/Settings/#comment')).to eq('Host foo: manage host foo')
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
          ensure: p.get(:ensure),
          condition: p.get(:condition),
        }
      end

      expect(inst.size).to eq(2)
      expect(inst[0]).to eq(condition: 'User anoncvs', ensure: :present)
      expect(inst[1]).to eq(condition: 'Host *.example.net User *', ensure: :present)
    end

    context 'when creating settings' do
      it 'adds a new Match group at the end' do
        apply!(Puppet::Type.type(:sshd_config_match).new(
                 name: 'Foo bar',
                 target: target,
                 ensure: :present,
                 provider: 'augeas'
               ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.match('Match/Condition/Foo')[0]).to end_with('/Match[3]/Condition/Foo')
          expect(aug.get('Match/Condition/Foo')).to eq('bar')
        end
      end

      it 'adds a new Match group before first group' do
        apply!(Puppet::Type.type(:sshd_config_match).new(
                 name: 'Bar baz',
                 position: 'before first match',
                 target: target,
                 ensure: :present,
                 provider: 'augeas'
               ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.match('Match/Condition/Bar')[0]).to end_with('/Match[1]/Condition/Bar')
          expect(aug.get('Match/Condition/Bar')).to eq('baz')
        end
      end

      it 'adds a new Match group before specific group' do
        apply!(Puppet::Type.type(:sshd_config_match).new(
                 name: 'Fooz bar',
                 position: 'before User * Host *.example.net',
                 target: target,
                 ensure: :present,
                 provider: 'augeas'
               ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.match('Match/Condition/Fooz')[0]).to end_with('/Match[2]/Condition/Fooz')
          expect(aug.get('Match/Condition/Fooz')).to eq('bar')
        end
      end

      it 'creates new comment before entry' do
        apply!(Puppet::Type.type(:sshd_config_match).new(
                 name: 'User bar',
                 target: target,
                 comment: 'bar is a user',
                 provider: 'augeas'
               ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.get('Match[Condition/User]/Settings/#comment')).to eq('User bar: bar is a user')
        end
      end
    end

    context 'when deleting settings' do
      it 'deletes a Match group' do
        apply!(Puppet::Type.type(:sshd_config_match).new(
                 name: 'User anoncvs',
                 target: target,
                 ensure: :absent,
                 provider: 'augeas'
               ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.match("Match/Condition/User[.='anoncvs']").size).to eq(0)
        end
      end

      it 'deletes a comment' do
        apply!(Puppet::Type.type(:sshd_config_match).new(
                 name: 'User anoncvs',
                 ensure: 'absent',
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Ssh.lns') do |aug|
          expect(aug.match('Match[Condition/User]/Settings/#comment').size).to eq(0)
        end
      end
    end

    context 'when updating settings' do
      it 'moves existing Match group to the end' do
        apply!(Puppet::Type.type(:sshd_config_match).new(
                 name: 'User anoncvs',
                 position: 'after last match',
                 target: target,
                 ensure: :positioned,
                 provider: 'augeas'
               ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.match("Match/Condition/User[.='anoncvs']")[0]).to end_with('/Match[2]/Condition/User')
          expect(aug.get('Match[2]/Condition/User')).to eq('anoncvs')
          expect(aug.get('Match[2]/Settings/X11Forwarding')).to eq('no')
        end
      end

      it 'replaces the comment' do
        apply!(Puppet::Type.type(:sshd_config_match).new(
                 name: 'User anoncvs',
                 target: target,
                 provider: 'augeas',
                 comment: 'This is a different comment'
               ))

        aug_open(target, 'Sshd.lns') do |aug|
          expect(aug.get('Match[Condition/User]/Settings/#comment')).to eq('User anoncvs: This is a different comment')
        end
      end
    end
  end

  context 'with broken file' do
    let(:tmptarget) { aug_fixture('broken') }
    let(:target) { tmptarget.path }

    it 'fails to load' do
      txn = apply(Puppet::Type.type(:sshd_config_match).new(
                    name: 'Host foo',
                    target: target,
                    provider: 'augeas'
                  ))

      expect(txn.any_failed?).not_to eq(nil)
      expect(@logs.first.level).to eq(:err)
      expect(@logs.first.message.include?(target)).to eq(true)
    end
  end
end
