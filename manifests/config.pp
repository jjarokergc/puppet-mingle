# Mingle Configuration
# Install config files
class profile::mingle::config {
  ### Variables
  # Tomcat Server Parameters
  $s = lookup('mingle::server')
  $n = $s['instance']

  # Tomcat Server
  $tomcat = $s['tomcat']

  # Mingle Instance
  $catalina_base = $n['catalina']['base'] # Ex: /opt/mingle
  $config_dir = "${catalina_base}/${n['dir']['config']}"  # Ex: /opt/mingle/conf

  $common_attributes = { # Common attributes to the file resources below
    'ensure' => 'file',
    'owner' => $tomcat['user'],
    'group' => $tomcat['user'],
    'mode' => '0640',
    'notify'  => Service['mingle'],
  }

  # Run tomcat as a service
  file { 'Mingle Unit File':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    path    => '/etc/systemd/system/mingle.service',
    content => epp('mingle.service.epp', {
        'n'               => $n,
        'service_account' => $tomcat['user'],
    }, ),
    notify  => Service['mingle'],
  }
  # Environment variables are defined in setenv
  file { 'Mingle Environment Variables':
    path    => "${catalina_base}/bin/setenv.sh",
    content => epp('mingle.setenv.sh.epp', { 'n' => $n, }),
    *       => $common_attributes,
  }

  file { 'Mingle Log4J Properties':
    path    => "${config_dir}/log4j.properties",
    content => epp('log4j.properties.epp', { 'n' => $n, }),
    *       => $common_attributes,
  }

  file { 'Mingle Database Config':
    path    => "${config_dir}/database.yml",
    content => epp('database.yml.epp', { 'n' => $n, }),
    *       => $common_attributes,
  }
  file { 'Mingle SMTP Config':
    path    => "${config_dir}/smtp_config.yml",
    content => epp('smtp_config.yml.epp', { 's' => $s, }),
    *       => $common_attributes,
  }
  file { 'Mingle Properties':
    path    => "${config_dir}/mingle.properties",
    replace => false, # Create the initial file but allow Mingle to manage it
    content => epp('mingle.properties.epp', { 'n' => $n, }),
    *       => $common_attributes,
  }
}
