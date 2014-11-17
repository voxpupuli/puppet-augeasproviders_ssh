#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:ssh_config).provider(:augeas)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/ssh/ssh_config').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:ssh_config).new(
        :name     => "ForwardAgent",
        :value    => "yes",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Ssh.lns") do |aug|
        aug.get("Host/ForwardAgent").should == "yes"
      end
    end

    it "should create an array entry" do
      apply!(Puppet::Type.type(:ssh_config).new(
        :name     => "SendEnv",
        :value    => ["LANG", "LC_TYPE"],
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Ssh.lns") do |aug|
        aug.get("Host/SendEnv/1").should == "LANG"
        aug.get("Host/SendEnv/2").should == "LC_TYPE"
      end
    end

    it "should create new entry for a host" do
      apply!(Puppet::Type.type(:ssh_config).new(
        :name      => "ForwardAgent",
        :host      => "example.net",
        :value     => "yes",
        :target    => target,
        :provider  => "augeas"
      ))

      aug_open(target, "Ssh.lns") do |aug|
        aug.get("Host[.='example.net']/ForwardAgent").should == "yes"
      end
    end

    context "when declaring two resources with same key" do
      it "should fail with same name" do
        expect do 
          apply!(
            Puppet::Type.type(:ssh_config).new(
              :name      => "ForwardAgent",
              :value     => "no",
              :target    => target,
              :provider  => "augeas"
            ),
            Puppet::Type.type(:ssh_config).new(
              :name      => "ForwardAgent",
              :host      => "example.net",
              :value     => "yes",
              :target    => target,
              :provider  => "augeas"
            )
          )
        end.to raise_error(Puppet::Resource::Catalog::DuplicateResourceError)
      end

      it "should fail with different names, same key and no host" do
        expect do 
          apply!(
            Puppet::Type.type(:ssh_config).new(
              :name      => "ForwardAgent",
              :value     => "no",
              :target    => target,
              :provider  => "augeas"
            ),
            Puppet::Type.type(:ssh_config).new(
              :name      => "Example ForwardAgent",
              :key       => "ForwardAgent",
              :value     => "yes",
              :target    => target,
              :provider  => "augeas"
            )
          )
        end.to raise_error
      end

      it "should not fail with different names, same key and different hosts" do
        expect do 
          apply!(
            Puppet::Type.type(:ssh_config).new(
              :name      => "ForwardAgent",
              :value     => "no",
              :target    => target,
              :provider  => "augeas"
            ),
            Puppet::Type.type(:ssh_config).new(
              :name      => "Example ForwardAgent",
              :key       => "ForwardAgent",
              :host      => "example.net",
              :value     => "yes",
              :target    => target,
              :provider  => "augeas"
            )
          )
        end.not_to raise_error
      end
    end
  end

  context "with full file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    it "should list instances" do
      provider_class.stubs(:target).returns(target)
      inst = provider_class.instances.map { |p|
        {
          :name   => p.get(:name),
          :ensure => p.get(:ensure),
          :value  => p.get(:value),
          :key    => p.get(:key),
          :host   => p.get(:host),
        }
      }

      inst.size.should == 4
      inst[0].should == {:name=>"SendEnv", :ensure=>:present, :value=>["LANG", "LC_*"], :key=>"SendEnv", :host=>"*"}
      inst[1].should == {:name=>"HashKnownHosts", :ensure=>:present, :value=>["yes"], :key=>"HashKnownHosts", :host=>"*"}
      inst[2].should == {:name=>"GSSAPIAuthentication", :ensure=>:present, :value=>["yes"], :key=>"GSSAPIAuthentication", :host=>"*"}
      inst[3].should == {:name=>"GSSAPIDelegateCredentials", :ensure=>:present, :value=>["no"], :key=>"GSSAPIDelegateCredentials", :host=>"*"}
    end

    describe "when creating settings" do
      it "should add an entry to a new host" do
        apply!(Puppet::Type.type(:ssh_config).new(
          :name      => "ForwardAgent",
          :host      => "example.net",
          :value     => "yes",
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Ssh.lns") do |aug|
          aug.get("Host[.='example.net']/ForwardAgent").should == "yes"
        end
      end

      it "should create an array entry" do
        apply!(Puppet::Type.type(:ssh_config).new(
          :name      => "SendEnv",
          :host      => "example.net",
          :value     => ["LC_*", "LANG"],
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Ssh.lns") do |aug|
          aug.get("Host[.='example.net']/SendEnv/1").should == "LC_*"
          aug.get("Host[.='example.net']/SendEnv/2").should == "LANG"
        end
      end
    end

    describe "when deleting settings" do
      it "should delete a setting" do
        apply!(Puppet::Type.type(:ssh_config).new(
          :name      => "HashKnownHosts",
          :ensure    => "absent",
          :host      => "*",
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Ssh.lns") do |aug|
          aug.match("Host[.='*']/HashKnownHosts").size.should == 0
        end
      end
    end

    describe "when updating settings" do
      it "should replace a setting" do
        apply!(Puppet::Type.type(:ssh_config).new(
          :name      => "HashKnownHosts",
          :host      => "*",
          :value     => "no",
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Ssh.lns") do |aug|
          aug.get("Host[.='*']/HashKnownHosts").should == "no"
        end
      end

      it "should replace the array setting" do
        apply!(Puppet::Type.type(:ssh_config).new(
          :name      => "SendEnv",
          :host      => "*",
          :value     => ["foo", "bar"],
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Ssh.lns") do |aug|
          aug.match("Host[.='*']/SendEnv/*").size.should == 2
          aug.get("Host[.='*']/SendEnv/1").should == "foo"
          aug.get("Host[.='*']/SendEnv/2").should == "bar"
        end
      end

      it "should replace settings case insensitively when on Augeas >= 1.0.0", :if => provider_class.supported?(:regexpi) do
        apply!(Puppet::Type.type(:ssh_config).new(
          :name     => "GssaPiaUthentication",
          :value    => "yes",
          :target   => target,
          :provider => "augeas"
        ))
  
        aug_open(target, "Ssh.lns") do |aug|
          aug.match("Host[.='*']/*[label()=~regexp('GSSAPIAuthentication', 'i')]").size.should == 1
          aug.get("Host[.='*']/GSSAPIAuthentication").should == "yes"
        end
      end

      it "should not replace settings case insensitively when on Augeas < 1.0.0" do
        provider_class.stubs(:supported?).with(:post_resource_eval)
        provider_class.stubs(:supported?).with(:regexpi).returns(false)
        apply!(Puppet::Type.type(:ssh_config).new(
          :name     => "GSSAPIDeLeGateCreDentials",
          :value    => "yes",
          :target   => target,
          :provider => "augeas"
        ))
  
        aug_open(target, "Ssh.lns") do |aug|
          aug.match("Host[.='*']/GSSAPIDelegateCredentials").size.should == 1
          aug.match("Host[.='*']/GSSAPIDeLeGateCreDentials").size.should == 1
          aug.get("Host[.='*']/GSSAPIDelegateCredentials").should == "no"
          aug.get("Host[.='*']/GSSAPIDeLeGateCreDentials").should == "yes"
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:ssh_config).new(
        :name     => "ForwardAgent",
        :value    => "yes",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
