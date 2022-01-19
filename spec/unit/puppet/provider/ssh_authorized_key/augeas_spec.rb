#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:ssh_authorized_key).provider(:augeas)

describe provider_class do
  let (:user) {
    File.stat(target).uid
  }

  let(:lens_exists?) {
    Augeas.open(nil, nil, Augeas::NO_LOAD) { |aug|
      aug.match('/augeas/load/Authorized_Keys').size == 1
    }
  }

  before :each do
    FileTest.stubs(:exist?).returns false
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      pending "Lens doesn't exist" unless lens_exists?
      apply!(Puppet::Type.type(:ssh_authorized_key).new(
        :name     => "nick@example.com",
        :user     => user,
        :type     => "ssh-rsa",
        :key      => "AAADEADMEAT==",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Authorized_Keys.lns") do |aug|
        aug.get("key").should == "AAADEADMEAT=="
      end
    end
  end

  context "with full file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    describe "when creating settings" do
      it "should create new entry" do
        pending "Lens doesn't exist" unless lens_exists?
        apply!(Puppet::Type.type(:ssh_authorized_key).new(
          :name     => "nick@example.com",
          :user     => user,
          :type     => "ssh-rsa",
          :key      => "AAADEADMEAT==",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Authorized_Keys.lns") do |aug|
          aug.get("key[.='AAADEADMEAT==']/comment").should == "nick@example.com"
        end
      end

      it "should create new entry with options" do
        pending "Lens doesn't exist" unless lens_exists?
        apply!(Puppet::Type.type(:ssh_authorized_key).new(
          :name     => "sue@example.com",
          :user     => user,
          :type     => "ssh-rsa",
          :key      => "ADEADMEATBB==",
          :options  => [ "no-pty", 'command="/usr/bin/secure-shell"'],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Authorized_Keys.lns") do |aug|
          aug.match("key[comment='sue@example.com']/options/no-pty").size.should == 1
          aug.get("key[comment='sue@example.com']/options/command").should == "/usr/bin/secure-shell"
        end
      end
    end

    describe "when deleting settings" do
      it "should remove entry" do
        pending "Lens doesn't exist" unless lens_exists?
        apply!(Puppet::Type.type(:ssh_authorized_key).new(
          :name     => "user@example.net",
          :ensure   => "absent",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Authorized_Keys.lns") do |aug|
          aug.match("key[comment='user@example.net']").size.should == 0
        end
      end
    end

    describe "when updating settings" do
      it "should change the user's key" do
        pending "Lens doesn't exist" unless lens_exists?
        apply!(Puppet::Type.type(:ssh_authorized_key).new(
          :name     => "user@example.net",
          :key      => "DEADMEAT",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Authorized_Keys.lns") do |aug|
          aug.get("key[comment='user@example.net']").should == "DEADMEAT"
        end
      end

      it "should add options to entry" do
        pending "Lens doesn't exist" unless lens_exists?
        apply!(Puppet::Type.type(:ssh_authorized_key).new(
          :name     => "user@example.net",
          :options  => ['tunnel="1"'],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Authorized_Keys.lns") do |aug|
          aug.match("key[comment='user@example.net']/options/*").size.should == 1
          aug.get("key[comment='user@example.net']/options/tunnel").should == "1"
        end
      end

      it "should remove all options" do
        pending "Lens doesn't exist" unless lens_exists?
        apply!(Puppet::Type.type(:ssh_authorized_key).new(
          :name     => "john@example.net",
          :options  => [:absent],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Authorized_Keys.lns") do |aug|
          aug.match("key[comment='john@example.net']/options/*").size.should == 0
        end
      end

      it "should change the command option" do
        pending "Lens doesn't exist" unless lens_exists?
        apply!(Puppet::Type.type(:ssh_authorized_key).new(
          :name     => "jane@example.net",
          :options  => ['command="/bin/false"'],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Authorized_Keys.lns") do |aug|
          aug.get("key[comment='jane@example.net']/options/command").should == "/bin/false"
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      pending "Lens doesn't exist" unless lens_exists?
      txn = apply(Puppet::Type.type(:ssh_authorized_key).new(
        :name     => "nick@example.com",
        :user     => "nick",
        :type     => "ssh-rsa",
        :key      => "AAADEADMEAT==",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
