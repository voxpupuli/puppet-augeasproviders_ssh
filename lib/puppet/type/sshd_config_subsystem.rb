# frozen_string_literal: true

# Manages Subsystem settings in OpenSSH's sshd_config file
#
# Copyright (c) 2012-2020 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:sshd_config_subsystem) do
  @doc = 'Manages Subsystem settings in an OpenSSH sshd_config file.'

  ensurable

  newparam(:name) do
    desc 'The name of the subsystem to set.'
    isnamevar
  end

  newproperty(:command) do
    desc 'The command to execute upon subsystem request.'
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
      `/etc/ssh/sshd_config`."
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
