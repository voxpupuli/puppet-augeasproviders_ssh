# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2014 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.type(:ssh_authorized_key).provide(:augeas, :parent => Puppet::Type.type(:augeasprovider).provider(:default)) do
  desc "Uses Augeas API to update ssh authorized keys"

  default_file { '' }

  lens { 'Authorized_Keys.lns' }

  confine :feature => :augeas
  confine :true => Augeas.open(nil, nil, Augeas::NO_LOAD) { |aug| aug.match('/augeas/load/Authorized_Keys').size == 1 }
  defaultfor :feature => :augeas

  resource_path do |resource|
    "$target/*[comment='#{resource[:name]}']"
  end

  def self.set_options(aug, values)
    aug.rm('$resource/options/*')
    values.each do |opt|
      break if opt == :absent
      k, v = opt.split('=')
      if v.nil?
        aug.clear("$resource/options/#{k}")
      else
        aug.set("$resource/options/#{k}", v[1..-2])  # Strip quotes
      end
    end
    # Purge empty options nodes
    aug.rm('$resource/options[count(*)=0]')
  end

  define_aug_method!(:create) do |aug, resource|
    aug.defnode('resource', "$target/key[comment='#{resource[:name]}']", resource[:key])
    set_options(aug, resource[:options])
    aug.set('$resource/type', resource[:type].to_s)
    aug.set('$resource/comment', resource[:name])
  end

  def options=(values) 
    augopen! do |aug|
      self.class.set_options(aug, values)
    end
  end

  define_aug_method(:options) do |aug, resource|
    options = aug.match('$resource/options/*')
    if options.empty?
      [:absent]
    else
      options.map do |opt|
        label = path_label(aug, opt)
        value = aug.get(opt)
        if value.nil?
          label
        else
          %Q{#{label}="#{value}"}
        end
      end
    end
  end

  def user
    File.stat(target).uid
  end

  attr_aug_accessor(:type)
  attr_aug_accessor(:key, :label => :resource)
end
