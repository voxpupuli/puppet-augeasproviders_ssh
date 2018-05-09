# Changelog

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
