# frozen_string_literal: true

# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2015-2020 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

# Patch sshkey type to add feature and associated param
class Puppet::Type::Sshkey
  feature :hashed_hostnames,
          'The provider supports hashed hostnames.'

  newparam(:hash_hostname, boolean: true, required_features: :hashed_hostnames) do
    defaultto :false
  end
end

# Patch sshkey's ensure parameter to add hashed value
class Puppet::Type::Sshkey::Ensure
  newvalue(:hashed) do
    current = retrieve
    if current == :absent
      provider.create
    elsif !provider.hashed?
      provider.force_hash
    end
  end

  def insync?(is)
    return true if should == :hashed && is == :present && provider.hashed?

    super
  end
end

raise('Missing augeasproviders_core dependency') if Puppet::Type.type(:augeasprovider).nil?

Puppet::Type.type(:sshkey).provide(:augeas, parent: Puppet::Type.type(:augeasprovider).provider(:default)) do
  desc 'Uses Augeas API to update SSH known_hosts entries'

  has_features :hashed_hostnames

  default_file { '/etc/ssh/ssh_known_hosts' }

  lens { 'Known_Hosts.lns' }

  confine feature: :augeas
  defaultfor feature: :augeas

  def self.instances
    augopen do |aug, _path|
      resources = []
      aug.match('$target/*[label()!="#comment"]').each do |spath|
        name = aug.get(spath)
        # We only list non-hashed entries
        next if name.start_with? '|1|'

        aliases = aug.match("#{spath}/alias").map { |apath| aug.get(apath) }
        resources << new(ensure: :present,
                         name: name,
                         type: aug.get("#{spath}/type"),
                         key: aug.get("#{spath}/key"),
                         host_aliases: aliases,
                         hash_hostname: false,
                         target: target)
      end
      resources
    end
  end

  # Override self.setvars to set $resource
  def self.setvars(aug, resource = nil)
    aug.set('/augeas/context', "/files#{target(resource)}")
    aug.defnode('target', "/files#{target(resource)}", nil)
    return unless resource

    # HACK: set to /non/existent so that exists? is happy
    path = find_resource(aug, resource[:name]) || '/non/existent'
    aug.defvar('resource', path)
  end

  def self.find_resource(aug, hostname)
    aug.match('$target/*[label()!="#comment"]').each do |entry|
      hostnames = aug.get(entry)

      # Clear value
      return entry if hostnames.split(',')[0] == hostname

      next unless hashed?(hostnames)

      require 'base64'
      _dummy, _one, salt64, hostname64 = hostnames.split[0].split('|')
      salt = Base64.decode64(salt64)
      return entry if hostname64 == Base64.encode64(OpenSSL::HMAC.digest('sha1', salt, hostname)).strip
    end
    nil
  end

  def self.hashed?(string)
    string&.start_with?('|')
  end

  def resource_hashed?(aug)
    self.class.hashed?(aug.get('$resource'))
  end

  def hashed?
    augopen do |aug|
      resource_hashed?(aug)
    end
  end

  def self.new_hash(hostname)
    require 'securerandom'
    require 'base64'
    salt = SecureRandom.random_bytes(20)
    salt_b64 = Base64.encode64(salt).strip
    hostname_b64 = Base64.encode64(OpenSSL::HMAC.digest('sha1', salt, hostname)).strip
    "|1|#{salt_b64}|#{hostname_b64}"
  end

  def create_entry(aug, name, type, key, hash_hostname, aliases = [])
    seq = next_seq(aug.match('$target/*[label()!="#comment"]'))
    path = "$target/#{seq}"

    if hash_hostname
      aug.defnode('resource', path, self.class.new_hash(name))
    else
      aug.defnode('resource', path, name)
      (aliases || []).each do |a|
        aug.set('$resource/alias[last()+1]', a)
      end
    end

    set_value(aug, 'type', type)
    set_value(aug, 'key', key)
  end

  def create
    augopen! do |aug|
      if resource[:hash_hostname] == :true
        [resource[:name], resource[:host_aliases]].flatten.compact.each do |h|
          create_entry(aug, h, resource[:type], resource[:key], true)
        end
      else
        create_entry(aug, resource[:name], resource[:type], resource[:key], false, resource[:host_aliases])
      end
    end
  end

  def destroy
    augopen! do |aug|
      if resource_hashed?(aug)
        resource[:host_aliases].each do |a|
          aug.rm(self.class.find_resource(aug, a))
        end
      end
      aug.rm('$resource')
    end
  end

  def force_hash
    augopen! do |aug|
      aug.set('$resource', self.class.new_hash(resource[:name]))

      # Get existing values
      type = aug.get('$resource/type')
      key = aug.get('$resource/key')

      # Careful: create_entry redefines $resource!
      aliases = aug.match('$resource/alias')
      aug.rm('$resource/alias')

      aliases.each do |a|
        create_entry(aug, a, type, key, true)
      end
    end
  end

  def host_aliases
    augopen do |aug|
      if resource_hashed?(aug)
        # We cannot know about unmanaged aliases when hashed
        resource[:host_aliases].map do |a|
          a if self.class.find_resource(aug, a)
        end.compact
      else
        aug.match('$resource/alias').map do |a|
          aug.get(a)
        end
      end
    end
  end

  def host_aliases=(values)
    augopen! do |aug|
      if resource_hashed?(aug)
        values.each do |v|
          create_entry(aug, v, resource[:type], resource[:key], true) unless self.class.find_resource(aug, v)
        end
      else
        aug.rm('$resource/alias')
        values.each do |v|
          aug.insert('$resource/type', 'alias', true)
          aug.set('$resource/alias[last()]', v)
        end
      end
    end
  end

  def get_value(aug, label)
    if resource_hashed?(aug)
      # Use AND to make convergence fail if aliases are not in sync
      [resource[:name], resource[:host_aliases]].flatten.compact.map do |h|
        aug.get("#{self.class.find_resource(aug, h)}/#{label}")
      end.uniq.join(' AND ')
    else
      aug.get("$resource/#{label}")
    end
  end

  def set_value(aug, label, value)
    raise(Puppet::Error, "#{label} is mandatory") unless value

    aug.set("$resource/#{label}", value.to_s)

    return unless resource_hashed?(aug) && resource[:host_aliases]

    resource[:host_aliases].each do |h|
      aug.set("#{self.class.find_resource(aug, h)}/#{label}", value.to_s)
    end
  end

  def type
    augopen do |aug|
      get_value(aug, 'type')
    end
  end

  def type=(value)
    augopen! do |aug|
      set_value(aug, 'type', value)
    end
  end

  def key
    augopen do |aug|
      get_value(aug, 'key')
    end
  end

  def key=(value)
    augopen! do |aug|
      set_value(aug, 'key', value)
    end
  end
end
