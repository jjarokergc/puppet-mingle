# Set up Mingle development environment, build mingle, start server
#
class profile::mingle::build {
  ###
  ###
  ### BUILD ENVIRONMENT
  ###
  ###

  ### Create Accounts
  include profile::mingle::accounts

  ### Download Dependencies
  # Install Packages for Mingle build
  include profile::mingle::packages
  # Enable Git access to mingle source repo
  include profile::mingle::git
  # Download source files using archive module... 
  include profile::mingle::archive          # ...defined in 'archive::files'
  # Clone Repositories using vcsrpo module ...
  include profile::mingle::vcsrepo          # ... defined in 'vcsrepo::repos'
  # Create Mingle databases. Postgresql server is installed externally.
  include profile::mingle::database
  # Add highcharts to mingle
  include profile::mingle::highcharts
  # Install NVM and node v8.16.2 for Mingle-Rails5
  include profile::mingle::nvm

  # Mingle Build Variables
  $b = lookup('mingle::build')
  $links = $b['links']
  # Mingle Server Parameters
  $s = lookup('mingle::server')

  $mingle_user = $b['account']['user']

  # Source File Locations
  $mingle_home_dir = $b['account']['homedir']                   # Mingle user's home directory, Ex: /home/jjaroker
  $mingle_src = "${mingle_home_dir}/${b['account']['workspace']}"   # Checkout directory, Ex: /home/jjaroker/mingle
  $mingle_rails2_workingdir = "${mingle_src}/mingle" # Where scripts are executed Ex: /home/jjaroker/mingle/mingle
  $mingle_rails5_workingdir = "${mingle_src}/mingle-rails5" # Where scripts are executed Ex: /home/jjaroker/mingle/mingle

  # Build Scripts
  $rbenv_path = "${mingle_home_dir}/.rbenv/bin"
  $mingle_buildcommand = "${mingle_rails2_workingdir}/script/build"
  $mingle_rails5_buildcommand = "${mingle_rails5_workingdir}/go"
  $mingle_installercommand = "${mingle_src}/generate-installers.sh"
  $mingle_assetscommand = "${rbenv_path}/rbenv exec ruby -S bundle exec rake web_xml assets"
  $mingle_docscommand = "${rbenv_path}/rbenv exec ruby -S bundle exec rake installers:help" # Creates help pages in public folder

  # Flags used for exec resources
  $war_file = $b['rails2']['build_creates']                     # Mingle WAR File, Ex ROOT.war
  $war_source = "${mingle_rails2_workingdir}/${war_file}"
  $war_rails5_file = $b['rails5']['build_creates']              # Mingle Rails5 File, Ex: rails_5.war
  $war_rails5_source = "${mingle_rails2_workingdir}/${war_rails5_file}"
  $build_flag = '.puppetBuildOK'              # Flag used to mark successful build. Only run if flag absent
  $assets_flag = '.puppetAssetsOK'            # Flag to confirm build assets have been produced
  $docs_flag = '.puppetDocsOK'                # Flag for help files, which will be loaded into /public directory
  $build_rails5_flag = '.puppetBuildRails5OK' # Flag mingle-rails5 'go' script build

  # Environment variables
  $mingle_path = ['/bin','/usr/bin',$rbenv_path,]

  # Add Symlinks to Mingle's Build Workspace
  $links.each | $i, $v | {
    $target = $v['target']
    $path = "${mingle_src}/${v['subdir']}"

    file { "Mingle Build Symlink ${i}":
      ensure  => link,
      path    => $path,
      target  => $target,
      require => VCSRepo[$mingle_src],
      before  => Exec['Build Mingle'],
    }
  }

  ###
  ###
  ### BUILDING MINGLE Rails 2.3.18
  ###
  ###

  $common_attributes = {
    'user'        => $mingle_user,
    'path'        => $mingle_path,
    'environment' => ["HOME=${mingle_home_dir}"],
  }
  # Execute mingle build script
  exec { 'Build Mingle':
    cwd     => $mingle_rails2_workingdir,
    command => "${mingle_buildcommand} && touch ${build_flag}",
    creates => "${mingle_rails2_workingdir}/${build_flag}",
    timeout => 600,
    require => VCSRepo[$mingle_src],
    *       => $common_attributes,
  }

  # Generate Mingle Assets
  exec { 'Generate Mingle Assets':
    cwd     => $mingle_rails2_workingdir,
    command => "${mingle_assetscommand} && touch ${assets_flag}",
    creates => "${mingle_rails2_workingdir}/${assets_flag}",
    require => Exec['Build Mingle'],
    *       => $common_attributes,
  }

  # Generate Mingle Documentation
  exec { 'Generate Mingle Help Files':
    cwd     => $mingle_rails2_workingdir,
    command => "${mingle_docscommand} && touch ${docs_flag}",
    creates => "${mingle_rails2_workingdir}/${docs_flag}",
    require => Exec['Generate Mingle Assets'],
    *       => $common_attributes,
  }

  ###
  ###
  ### BUILDING MINGLE Rails 5
  ###
  ###

  exec { 'Build Mingle-Rails5':
    cwd     => $mingle_rails5_workingdir,
    command => "${mingle_rails5_buildcommand} && touch ${build_rails5_flag}",
    creates => "${mingle_rails5_workingdir}/${build_rails5_flag}",
    require => [Exec['Build Mingle'], Class['yarn']],
    *       => $common_attributes,
  }

  ###
  ###
  ### GENERATE INSTALLERS
  ###
  ###

  exec { 'Mingle Generate Installers':
    cwd     => $mingle_src,
    command => $mingle_installercommand,
    creates => $war_source,
    timeout => 600,
    require => [
      Exec['Build Mingle'],
      Exec['Build Mingle-Rails5'],
    ],
    *       => $common_attributes,
  }
}
