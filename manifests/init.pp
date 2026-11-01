# @summary Main class for hash expansions of types
#
# @param ssh_configs Hash expansion of ssh_config type
# @param sshd_config_matches Hash expansion of sshd_config_matches type
# @param sshd_configs Hash expansion of sshd_config type
# @param sshd_config_subsystems Hash expansion of sshd_config_subsystems type
#
# @example Two sshd configurations as a hash
#    class{ augeasproviders_ssh:
#      sshd_configs => {
#        'PubkeyAuthentication' => {
#           'ensure' => 'present',
#           'value'  => 'yes',
#        },
#        'PermitRootLogin' => {
#           'ensure' => 'present',
#           'value'  => 'yes',
#        }
#      }
#    }
#
class augeasproviders_ssh (
  Stdlib::CreateResources $ssh_configs = {},
  Stdlib::CreateResources $sshd_config_matches = {},
  Stdlib::CreateResources $sshd_configs = {},
  Stdlib::CreateResources $sshd_config_subsystems = {},
) {
  $ssh_configs.each | $_title, $_params | {
    ssh_config { $_title:
      * => $_params,
    }
  }

  $sshd_config_matches.each | $_title, $_params | {
    sshd_config_match { $_title:
      * => $_params,
    }
  }

  $sshd_configs.each | $_title, $_params | {
    sshd_config { $_title:
      * => $_params,
    }
  }

  $sshd_config_subsystems.each | $_title, $_params | {
    sshd_config_subsystem { $_title:
      * => $_params,
    }
  }
}
