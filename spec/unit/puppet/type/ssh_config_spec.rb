# frozen_string_literal: true

require 'spec_helper'

ssh_config_type = Puppet::Type.type(:ssh_config)

describe ssh_config_type do
  context 'when setting parameters' do
    it 'accepts a name parameter' do
      resource = ssh_config_type.new name: 'foo'
      expect(resource[:name]).to eq('foo')
    end

    it 'accepts a key parameter' do
      resource = ssh_config_type.new name: 'foo', key: 'bar'
      expect(resource[:key]).to eq('bar')
    end

    it 'accepts a value array parameter' do
      resource = ssh_config_type.new name: 'MACs', value: %w[foo bar]
      expect(resource[:value]).to eq(%w[foo bar])
    end

    it 'accepts a target parameter' do
      resource = ssh_config_type.new name: 'foo', target: '/foo/bar'
      expect(resource[:target]).to eq('/foo/bar')
    end

    it 'fails if target is not an absolute path' do
      expect do
        ssh_config_type.new name: 'foo', target: 'foo'
      end.to raise_error
    end

    it 'accepts a host parameter' do
      resource = ssh_config_type.new name: 'foo', host: 'example.net'
      expect(resource[:host]).to eq('example.net')
    end

    it 'has * as default host value' do
      resource = ssh_config_type.new name: 'foo'
      expect(resource[:host]).to eq('*')
    end
  end
end
