# Install NodeJS for Mingle-Rails5 build
# - NVM 
# - NodeJS
# - Yarn
class profile::mingle::nvm {
  ### Variables
  $b = lookup('mingle::build')

  $mingle_user = $b['account']['user']

  # Node v8.16.2
  class { 'nvm':
    user         => $mingle_user,
    install_node => $b['rails5']['node_version'],
    # require      => Package['git','make','wget'],
    # manage_dependencies => false,
  }

  class { 'yarn': # Install using nvm
    user           => $mingle_user,
    install_method => 'nvm',
    manage_repo    => false,
    require        => Class['nvm'],
  }
}
