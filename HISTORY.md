## [4.0.0](https://github.com/voxpupuli/puppet-augeasproviders_ssh/tree/4.0.0) (2020-07-16)

- Deprecate support for Augeas < 1.0.0
- Update supported Ubuntu versions
- sshd_config: close array regexp (GH #54), fix GH #52
- sshd_config_match: remove duplicated condition param in test (GH #58)
- sshkey: do not test type update, it's a parameter in Puppet 6 (GH #59)
- Add support for comments in types and providers (GH #61)
- Update copyright and authors infos

## 3.3.0

- Add EL8 support
- Add 'Port' to the list of items supporting Arrays in the documentation

## 3.2.1

- Fix puppet requirement to < 7.0.0

## 3.2.0

- add support for Puppet 5 & 6
- deprecate support for Puppet < 5
- update supported OSes in metadata.json

## 3.1.0

- Add support for array_append to sshd_config type (GH #43)

## 3.0.0

- Fix support for 'puppet generate types'
- Bumped supported puppet version to less than 6.0.0
- Updated the spec_helper.rb to correctly load for Puppet 5
- Added CentOS and OracleLinux to supported OS list

## 2.5.3

- ssh_config: fix HostKeyAlgorithms and KexAlgorithms (#GH 36)

## 2.5.2

- Added docker acceptance test
- Refactor the travis.yml for the current LTS versions of Puppet

## 2.5.1

- Bugfix Release:
  - Allow multiple values for GlobalKnownHostsFile (#GH 32)
  - Ensure that AddressFamily comes before ListenAddress (#GH 34)

## 2.5.0

- Implement instances for sshkey (only for non-hashed entries)

## 2.4.0

- Add sshd_config_match type and provider (#GH 5)
- Purge multiple array entries in ssh_config provider (GH #12)

## 2.3.0

- Add sshkey provider (GH #13)
- sshd_config: munge condition parameter
- Improve test setup
- Get rid of Gemfile.lock
- Improve README badges

## 2.2.2

- Properly insert values after commented out entry if case doesn't match (GH #6)

## 2.2.1

- Convert specs to rspec3 syntax
- Fix metadata.json

## 2.2.0

- sshd_config: consider KexAlgorithms and Ciphers as array values (GH #4)

## 2.1.0

- Add ssh_config type & provider

## 2.0.0

- First release of split module.
