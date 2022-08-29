# frozen_string_literal: true

# Manages settings in OpenSSH's ssh_config file
#
# Copyright (c) 2012-2020 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:ssh_config) do
  @doc = "Manages settings in an OpenSSH ssh_config file.

The resource name is used for the setting name, but if the `host` is
given, then the name can be something else and the `key` given as the name
of the setting.
  "

  ensurable

  newparam(:name) do
    desc 'The name of the setting, or a unique string if `host` given.'
    isnamevar
  end

  newparam(:key) do
    desc "Overrides setting name to prevent resource conflicts if `host` is
given."
  end

  newproperty(:value, array_matching: :all) do
    desc "Value to change the setting to. The follow parameters take an array of values:

- MACs;
- Ciphers;
- SendEnv.

All other parameters take a string. When passing an array to other parameters, only the first value in the array will be considered."
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
`/etc/ssh/ssh_config`."

    validate do |v|
      raise ArgumentError, 'target must be an absolute path' unless Puppet::Util.absolute_path? v
    end
  end

  newparam(:host) do
    desc 'Host condition for the entry.'

    defaultto { '*' }
  end

  newproperty(:comment) do
    desc 'Text to be stored in a comment immediately above the entry.
    It will be automatically prepended with the name of the variable in order
    for the provider to know whether it controls the comment or not.'
  end

  autorequire(:file) do
    self[:target]
  end
end
