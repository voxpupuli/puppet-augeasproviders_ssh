# frozen_string_literal: true

# Manages settings in OpenSSH's sshd_config file
#
# Copyright (c) 2012-2020 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:sshd_config) do
  @doc = "Manages settings in an OpenSSH sshd_config file.

The resource name is used for the setting name, but if the `condition` is
given, then the name can be something else and the `key` given as the name
of the setting.

Subsystem entries are not managed by this type. There is a specific `sshd_config_subsystem` type to manage these entries."

  ensurable

  newparam(:name) do
    desc 'The name of the setting, or a unique string if `condition` given.'
    isnamevar
  end

  newparam(:key) do
    desc "Overrides setting name to prevent resource conflicts if `condition` is
given."
  end

  newproperty(:value, array_matching: :all) do
    desc "Value to change the setting to. The follow parameters take an array of values:

- AcceptEnv;
- AllowGroups;
- AllowUsers;
- Ciphers;
- DenyGroups;
- DenyUsers;
- Port;
- KexAlgorithms;
- MACs;
- HostKeyAlgorithms.

All other parameters take a string. When passing an array to other parameters, only the first value in the array will be considered."

    munge(&:to_s)

    def insync?(is)
      should_arr = Array(should)
      is_arr = Array(is)

      if provider.resource[:array_append]
        (should_arr - is_arr).empty?
      elsif should.size > 1
        should_arr == is_arr
      else
        should == is
      end
    end

    def sync
      if provider.resource[:array_append]
        # Merge the two arrays
        is = @resource.property(:value).retrieve
        is_arr = Array(is)

        provider.value = is_arr | Array(should)
      else
        # Use the should array
        provider.value = should
      end
    end

    def should_to_s(new_value)
      if provider.resource[:array_append]
        # Merge the two arrays
        is = @resource.property(:value).retrieve
        is_arr = Array(is)

        super(is_arr | Array(new_value))
      else
        super(new_value)
      end
    end
  end

  newparam(:array_append) do
    desc 'Whether to add to existing array values or replace all values.'

    newvalues :false, :true

    defaultto :false

    munge do |v|
      case v
      when true, 'true', :true
        true
      when false, 'false', :false
        false
      end
    end
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
`/etc/ssh/sshd_config`."
  end

  newparam(:condition) do
    desc "Match group condition for the entry,
in the format:

    sshd_config { 'PermitRootLogin':
      value     => 'without-password',
      condition => 'Host example.net',
    }

The value can contain multiple conditions, concatenated together with
whitespace.  This is used if the `Match` block has multiple criteria.

    condition => 'Host example.net User root'
    "

    munge do |value|
      if value.is_a? Hash
        # TODO: test this
        value
      else
        value_a = value.split
        Hash[*value_a]
      end
    end
  end

  newproperty(:comment) do
    desc 'Text to be stored in a comment immediately above the entry.
    It will be automatically prepended with the name of the variable in order
    for the provider to know whether it controls the comment or not.'
  end

  autorequire(:file) do
    self[:target]
  end

  autorequire(:sshd_config_match) do
    if self[:condition]
      names = []
      self[:condition].keys.permutation.to_a.each do |p|
        name = p.map { |k| "#{k} #{self[:condition][k]}" }.join(' ')
        names << name
        names << "#{name} in #{self[:target]}"
      end
      names
    end
  end
end
