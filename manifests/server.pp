# Class: Profile Mingle Server
# Install and configure Tomcat
# Deploy WAR file
# Start mingle instance
# Depends upon mingle::build
#
class mingle::server {
  ### Variables
  # Mingle Build Parameters
  $b = lookup('mingle::build')
  # Tomcat Server Parameters
  $s = lookup('mingle::server')
  $t = $s['tomcat']
  $n = $s['instance']

  # Tomcat Server
  $tomcat_version = $t['version']                                       # Ex: 8.5.93
  $tomcat_source = regsubst($t['source'], 'VER', $tomcat_version, 'G')  # Apache tomcat download url
  $tomcat_path = $t['path']                                             # Ex: /opt/tomcat -> /opt/apps/tomcat-8.5.93
  $tomcat_install_dir = "${t['install_dir']}/tomcat-${tomcat_version}"  # Ex: /opt/apps/tomcat-8.5.93

  # Mingle Instance
  $catalina_home = $n['catalina']['home']                 # Ex: /opt/tomcat
  $catalina_base = $n['catalina']['base']                 # Ex: /opt/mingle
  $config_dir = "${catalina_base}/${n['dir']['config']}"  # Ex: /opt/mingle/conf
  $java_home = $n['java']['home']                         # Points to JDK
  $port = $n['ports']

  # Mingle WAR Files
  $mingle_home_dir = $b['account']['homedir']                       # Mingle user's home directory, Ex: /home/jjaroker
  $mingle_dir = "${mingle_home_dir}/${b['account']['workspace']}"   # Checkout directory, Ex: /home/jjaroker/mingle
  $mingle_workingdir = "${mingle_dir}/mingle"                       # Where scripts are executed Ex: /home/jjaroker/mingle/mingle
  $war_file = $b['rails2']['build_creates']                         # Mingle WAR File, Ex ROOT.war
  $war_source = "${mingle_workingdir}/${war_file}"
  $war_rails5_file = $b['rails5']['build_creates']                  # Mingle Rails5 File, Ex: rails_5.war
  $war_rails5_source = "${mingle_workingdir}/${war_rails5_file}"

  ### TOMCAT SERVER
  # Create Tomcat source directory if it does not exist
  exec { "Tomcat Parent Dirs ${tomcat_install_dir}":
    command => "mkdir -p ${tomcat_install_dir}",
    creates => $tomcat_install_dir,
    path    => ['/bin', '/usr/bin'],
    before  => Tomcat::Install[$tomcat_install_dir],
  }
  tomcat::install { $tomcat_install_dir:
    source_url  => $tomcat_source,
    manage_home => true,
    user        => $t['user'],
    group       => $t['user'],
  }
  file { 'Tomcat symbolic link to current version':
    ensure  => link,
    path    => $tomcat_path,
    target  => $tomcat_install_dir,
    owner   => $t['user'],
    group   => $t['user'],
    require => Tomcat::Install[$tomcat_install_dir],
  }

  ### MINGLE INSTANCE
  tomcat::instance { 'mingle':
    catalina_home         => $catalina_home,
    catalina_base         => $catalina_base,
    require               => File['Mingle Unit File'],
    service_name          => 'mingle',
    use_init              => true,
    manage_service        => true,
    manage_copy_from_home => true, # Copy initial config files from tomcat to this instance
    user                  => $t['user'],
    group                 => $t['user'],
  }
  # Create tomcat-users.xml file
  # Required to silence log warning
  tomcat::config::server::tomcat_users { 'Mingle User':
    catalina_base => $catalina_base,
    element       => 'user',
    element_name  => 'mingle', # Username
    password      => 'password',
    roles         => ['manager-status'],
    owner         => $t['user'],
    group         => $t['user'],
  }
  # Server Attributes
  tomcat::config::server { 'mingle':
    catalina_base => $catalina_base,
    port          => $port['base'], # Port to listen for shutdown command
  }
  # Listen Socket
  # - removes 'redirectPort' because this instance only listens on http
  # - adds 'relaxed' attributes to allow mingle to use '[]' in urls, which is now bad practice
  tomcat::config::server::connector { "mingle-http-${port['http']}": 
    catalina_base         => $catalina_base,
    port                  => $port['http'],     # Server socket port
    protocol              => 'HTTP/1.1',
    purge_connectors      => true,
    attributes_to_remove  => ['redirectPort'],  # This instance is behind a reverse proxy and only listens on http
    additional_attributes => {
      'relaxedPathChars'  => '[ ]',             # Mingle requires "relaxed path" characters
      'relaxedQueryChars' => '[ ]',
    },
    require               => File["${catalina_base}/conf/server.xml"], # Added to solve a dependency problem in tomcat module
  }
  # Host Configuration 
  # - add the additional parameter 'deployOnStartup: false' for faster restarts
  tomcat::config::server::host { 'Mingle Host':
    catalina_base         => $catalina_base,
    host_name             => 'localhost',       # Name of the host to match
    app_base              => 'webapps',
    parent_service        => 'Catalina',        # Name attribute of Service element that contains this host stanza
    host_ensure           => 'present',
    additional_attributes => {
      'deployOnStartup' => 'false',             # Do not redeploy war when server restarts; redeploy only when war is first installed
    },
    require               => File["${catalina_base}/conf/server.xml"], # Added to solve a dependency problem in tomcat module
  }
  # Log Configuration
  # - use '.log' suffix (not '.txt')
  tomcat::config::server::valve { 'Mingle Access Log':
    catalina_base         => $catalina_base,
    parent_host           => 'localhost',
    class_name            => 'org.apache.catalina.valves.AccessLogValve',
    additional_attributes => {
      'directory' => 'logs',
      'prefix'    => 'localhost_access_log',
      'suffix'    => '.log',
      'pattern'   => '%h %l %u %t &quot;%r&quot; %s %b',
    },
    require               => File["${catalina_base}/conf/server.xml"], # Added to solve a dependency problem in tomcat module
  }

  ### MINGLE APP
  # - deploy mingle and rails5 war files that are produced by mingle::build
  tomcat::war { $war_file:
    war_source    => $war_source,
    catalina_base => $catalina_base,
    subscribe     => Exec['Mingle Generate Installers'],
    user          => $t['user'],
    group         => $t['user'],
  }
  tomcat::war { $war_rails5_file:
    war_source    => $war_rails5_source,
    catalina_base => $catalina_base,
    subscribe     => Exec['Mingle Generate Installers'],
    user          => $t['user'],
    group         => $t['user'],
  }
}
