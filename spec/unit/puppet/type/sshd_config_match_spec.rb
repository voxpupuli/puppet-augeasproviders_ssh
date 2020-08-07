#!/usr/bin/env rspec

require 'spec_helper'

sshd_config_match_type = Puppet::Type.type(:sshd_config_match)

describe sshd_config_match_type do
  context 'when setting parameters' do
    it 'accepts a name parameter' do
      resource = sshd_config_match_type.new name: 'foo'
      expect(resource[:name]).to eq('foo')
    end

    it 'accepts a condition parameter' do
      resource = sshd_config_match_type.new name: 'foo', condition: 'Host foo'
      expect(resource[:condition]).to eq('Host' => 'foo')
    end

    it 'accepts a target parameter' do
      resource = sshd_config_match_type.new name: 'foo', target: '/foo/bar'
      expect(resource[:target]).to eq('/foo/bar')
    end

    it 'accepts a position parameter' do
      resource = sshd_config_match_type.new name: 'foo', position: 'before Host bar'
      expect(resource[:position]).to eq(before: true, match: 'Host bar')
    end

    it 'has a full composite namevar' do
      resource = sshd_config_match_type.new title: 'Host foo User bar in /tmp/sshd_config'
      expect(resource[:name]).to eq('Host foo User bar in /tmp/sshd_config')
      expect(resource[:condition]).to eq('Host' => 'foo', 'User' => 'bar')
      expect(resource[:target]).to eq('/tmp/sshd_config')
    end

    it 'has a partial composite namevar' do
      resource = sshd_config_match_type.new title: 'Host foo User bar'
      expect(resource[:name]).to eq('Host foo User bar')
      expect(resource[:condition]).to eq('Host' => 'foo', 'User' => 'bar')
    end
  end
end
