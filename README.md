# puppet-augeasproviders\_ssh

[![Build Status](https://github.com/voxpupuli/puppet-augeasproviders_ssh/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-augeasproviders_ssh/actions?query=workflow%3ACI)
[![Release](https://github.com/voxpupuli/puppet-augeasproviders_ssh/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/puppet-augeasproviders_ssh/actions/workflows/release.yml)
[![Code Coverage](https://coveralls.io/repos/github/voxpupuli/puppet-augeasproviders_ssh/badge.svg?branch=master)](https://coveralls.io/github/voxpupuli/puppet-augeasproviders_ssh)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/augeasproviders_ssh.svg)](https://forge.puppetlabs.com/puppet/augeasproviders_ssh)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/augeasproviders_ssh.svg)](https://forge.puppetlabs.com/puppet/augeasproviders_ssh)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/augeasproviders_ssh.svg)](https://forge.puppetlabs.com/puppet/augeasproviders_ssh)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/augeasproviders_ssh.svg)](https://forge.puppetlabs.com/puppet/augeasproviders_ssh)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/puppet-augeasproviders_ssh)
[![Apache-2 License](https://img.shields.io/github/license/voxpupuli/puppet-augeasproviders_ssh.svg)](LICENSE)
[![Donated by Camptocamp](https://img.shields.io/badge/donated%20by-camptocamp-fb7047.svg)](#transfer-notice)

## ssh: type/provider for ssh files for Puppet

This module provides a new type/provider for Puppet to read and modify ssh
config files using the Augeas configuration library.

The advantage of using Augeas over the default Puppet `parsedfile`
implementations is that Augeas will go to great lengths to preserve file
formatting and comments, while also failing safely when needed.

This provider will hide *all* of the Augeas commands etc., you don't need to
know anything about Augeas to make use of it.

## Requirements

Ensure both Augeas and ruby-augeas 0.3.0+ bindings are installed and working as
normal. Both are usually bundled in the puppet agent AIO packages from Puppet Inc.

See [Puppet/Augeas pre-requisites](http://docs.puppetlabs.com/guides/augeas.html#pre-requisites).

## Installing

The module can be installed easily ([documentation](http://docs.puppetlabs.com/puppet/latest/reference/modules_installing.html)):

```bash
puppet module install puppet/augeasproviders_ssh
```

Ensure the module is present in your puppetmaster's own environment (it doesn't
have to use it) and that the master has pluginsync enabled.  Run the agent on
the puppetmaster to cause the custom types to be synced to its local libdir
(`puppet master --configprint libdir`) and then restart the puppetmaster so it
loads them.

## Compatibility

### Puppet versions

In theory. Puppet 2.7 is the minimal version. We currently (2022-08-29) test against Puppet 6 and 7.
Check the Puppet version range in `metadata.json` for supported versions.

### Augeas versions

| Augeas Versions         | 0.10.0  | 1.0.0   | 1.1.0   | 1.2.0   |
| :---------------------- | :-----: | :-----: | :-----: | :-----: |
| **FEATURES**            |         |         |         |         |
| case-insensitive keys   | no      | **yes** | **yes** | **yes** |
| **PROVIDERS**           |         |         |         |         |
| `ssh_config`            | **yes** | **yes** | **yes** | **yes** |
| `sshd_config`           | **yes** | **yes** | **yes** | **yes** |
| `sshd_config_match`     | **yes** | **yes** | **yes** | **yes** |
| `sshd_config_subsystem` | **yes** | **yes** | **yes** | **yes** |
| `sshkey`                | **yes** | **yes** | **yes** | **yes** |

## Documentation and examples

Type documentation can be generated with `puppet doc -r type` or viewed on the
[Puppet Forge page](http://forge.puppetlabs.com/herculesteam/augeasproviders_ssh).

### `ssh_config` provider

#### Manage simple entry

```puppet
ssh_config { 'ForwardAgent':
  ensure => present,
  value  => 'yes',
}
```

#### Manage array entry

```puppet
ssh_config { 'SendEnv':
  ensure => present,
  value  => ['LC_*', 'LANG'],
}
```

#### Manage entry for a specific host

```puppet
ssh_config { 'X11Forwarding':
  ensure => present,
  host   => 'example.net',
  value  => 'yes',
}
```

#### Manage entries with same name for different hosts

```puppet
ssh_config { 'ForwardAgent global':
  ensure => present,
  key    => 'ForwardAgent',
  value  => 'no',
}

ssh_config { 'ForwardAgent on example.net':
  ensure => present,
  key    => 'ForwardAgent',
  host   => 'example.net',
  value  => 'yes',
}
```

#### Manage entry with a comment

```puppet
ssh_config { 'ForwardAgent':
  ensure  => present,
  key     => 'ForwardAgent',
  value   => 'no',
  comment => 'Do not forward',
}
```

#### Delete entry

```puppet
ssh_config { 'HashKnownHosts':
  ensure => absent,
}

ssh_config { 'BatchMode':
  ensure => absent,
  host   => 'example.net',
}
```

#### Manage entry in another `ssh_config` location

```puppet
ssh_config { 'CheckHostIP':
  ensure => present,
  value  => 'yes',
  target => '/etc/ssh/another_sshd_config',
}
```

### `sshd_config` provider

#### Manage simple entry

```puppet
sshd_config { 'PermitRootLogin':
  ensure => present,
  value  => 'yes',
}
```

#### Manage array entry

```puppet
sshd_config { 'AllowGroups':
  ensure => present,
  value  => ['sshgroups', 'admins'],
}
```

#### Append to array entry

```puppet
sshd_config { 'AllowGroups':
  ensure       => present,
  value        => ['sshgroups', 'admins'],
  array_append => true,
}
```

#### Manage entry in a Match block

```puppet
sshd_config { 'X11Forwarding':
  ensure    => present,
  condition => 'Host foo User root',
  value     => 'yes',
}

sshd_config { 'AllowAgentForwarding':
  ensure    => present,
  condition => 'Host *.example.net',
  value     => 'yes',
}
```

#### Manage entries with same name in different blocks

```puppet
sshd_config { 'X11Forwarding global':
  ensure => present,
  key    => 'X11Forwarding',
  value  => 'no',
}

sshd_config { 'X11Forwarding foo':
  ensure    => present,
  key       => 'X11Forwarding',
  condition => 'User foo',
  value     => 'yes',
}

sshd_config { 'X11Forwarding root':
  ensure    => present,
  key       => 'X11Forwarding',
  condition => 'User root',
  value     => 'no',
}
```

#### Manage entry with a comment

```puppet
sshd_config { 'X11Forwarding':
  ensure  => present,
  key     => 'X11Forwarding',
  value   => 'no',
  comment => 'No X11',
}
```

#### Delete entry

```puppet
sshd_config { 'PermitRootLogin':
  ensure => absent,
}

sshd_config { 'AllowAgentForwarding':
  ensure    => absent,
  condition => 'Host *.example.net User *',
}
```

#### Manage entry in another `sshd_config` location

```puppet
sshd_config { 'PermitRootLogin':
  ensure => present,
  value  => 'yes',
  target => '/etc/ssh/another_sshd_config',
}
```

### `sshd_config_match` provider

#### Manage entry

```puppet
sshd_config_match { 'Host *.example.net':
  ensure => present,
}
```

#### Manage entry with position

```puppet
sshd_config_match { 'Host *.example.net':
  ensure   => present,
  position => 'before first match',
}

sshd_config_match { 'User foo':
  ensure   => present,
  position => 'after Host *.example.net',
}
```

#### Manage entry with a comment

```puppet
sshd_config_match { 'Host *.example.net':
  ensure  => present,
  comment => 'Example network',
}
```

#### Delete entry

```puppet
sshd_config_match { 'User foo Host *.example.net':
  ensure => absent,
}
```

#### Manage entry in another `sshd_config` location

```puppet
sshd_config_match { 'Host *.example.net':
  ensure => present,
  target => '/etc/ssh/another_sshd_config',
}
```

### `sshd_config_subsystem` provider

#### Manage entry

```puppet
sshd_config_subsystem { 'sftp':
  ensure  => present,
  command => '/usr/lib/openssh/sftp-server',
}
```

#### Manage entry with a comment

```puppet
sshd_config_subsystem { 'sftp':
  ensure  => present,
  command => '/usr/lib/openssh/sftp-server',
  comment => 'SFTP sub',
}
```

#### Delete entry

```puppet
sshd_config_subsystem { 'sftp':
  ensure => absent,
}
```

#### Manage entry in another `sshd_config` location

```puppet
sshd_config_subsystem { 'sftp':
  ensure  => present,
  command => '/usr/lib/openssh/sftp-server',
  target  => '/etc/ssh/another_sshd_config',
}
```

### `sshkey` provider

#### Manage entry

```puppet
sshkey { 'foo.example.com':
  ensure => present,
  type   => 'ssh-rsa',
  key    => 'AAADEADMEAT',
}
```

#### Manage entry with aliases

```puppet
sshkey { 'foo.example.com':
  ensure       => present,
  type         => 'ssh-rsa',
  key          => 'AAADEADMEAT',
  host_aliases => ['foo', '192.168.0.1'],
}
```

#### Manage hashed entry

```puppet
sshkey { 'foo.example.com':
  ensure        => present,
  type          => 'ssh-rsa',
  key           => 'AAADEADMEAT',
  hash_hostname => true,
}
```

#### Hash existing entry

```puppet
sshkey { 'foo.example.com':
  ensure        => hashed,
  type          => 'ssh-rsa',
  key           => 'AAADEADMEAT',
  hash_hostname => true,
}
```

#### Delete entry

```puppet
sshkey { 'foo.example.com':
  ensure => absent,
}
```

#### Manage entry in another `ssh_known_hosts` location

```puppet
sshkey { 'foo.example.com':
  ensure => present,
  type   => 'ssh-rsa',
  key    => 'AAADEADMEAT',
  target => '/root/.ssh/known_hosts',
}
```

## Issues

Please file any issues or suggestions [on GitHub](https://github.com/voxpupuli/puppet-augeasproviders_ssh/issues).
