#!/usr/bin/env rspec

require 'spec_helper'

ssh_config_type = Puppet::Type.type(:ssh_config)

describe ssh_config_type do
  context 'when setting parameters' do
    it 'should accept a name parameter' do
      resource = ssh_config_type.new :name => 'foo'
      resource[:name].should == 'foo'
    end

    it 'should accept a key parameter' do
      resource = ssh_config_type.new :name => 'foo', :key => 'bar'
      resource[:key].should == 'bar'
    end

    it 'should accept a value array parameter' do
      resource = ssh_config_type.new :name => 'MACs', :value => ['foo', 'bar']
      resource[:value].should == ['foo', 'bar']
    end

    it 'should accept a target parameter' do
      resource = ssh_config_type.new :name => 'foo', :target => '/foo/bar'
      resource[:target].should == '/foo/bar'
    end

    it 'should fail if target is not an absolute path' do
      expect {
        ssh_config_type.new :name => 'foo', :target => 'foo'
      }.to raise_error
    end

    it 'should accept a host parameter' do
      resource = ssh_config_type.new :name => 'foo', :host => 'example.net'
      resource[:host].should == 'example.net'
    end

    it 'should have * as default host value' do
      resource = ssh_config_type.new :name => 'foo'
      resource[:host].should == '*'
    end
  end
end

