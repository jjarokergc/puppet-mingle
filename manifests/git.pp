# Install git
# Add creditials to git repo for mingle download
# NOTE: configuration parameters are applied by git from hiera
class mingle::git {
  include git # Git config is defined in hiera git::configs, not here

  # Code Repo Keys
  $k = lookup('ssh::key')                 # ... defined in global yaml
  $kn = $k['known_hosts']                 # Known hosts hash from global.yaml
  $b = lookup('mingle::build')
  $s = lookup('mingle::server')

  $user_account = $b['account']
  $tomcat = $s['tomcat']

  # Add keys for following known_hosts
  $hosts = ['gitlab.jaroker.org']
  $hosts.each | $i, $v | { # index 'i' with value 'v'
    sshkey { $v :
      ensure  => present,
      type    => $kn[$v]['type'],
      key     => $kn[$v]['key'],
      target  => "${user_account['homedir']}/.ssh/known_hosts",
      before  => Vcsrepo["${user_account['homedir']}/${user_account['workspace']}"],
      require => File["${user_account['homedir']}/.ssh"],
    }
  } # For each host, add ssh key

  # Private ssh key for gitlab ssl access
  file { "/home/${user_account['user']}/.ssh/id_rsa":
    ensure  => 'file',
    mode    => '0600',
    owner   => $user_account['user'],
    group   => $user_account['user'],
    content => $k['private']['gitlab'],
    require => File["${user_account['homedir']}/.ssh"],
    before  => Vcsrepo["${user_account['homedir']}/${user_account['workspace']}"],
  }

  # Fix dependency for git config.  Home directory must be created first
  # before any Git::Config resource
  File[$user_account['homedir']] -> Git::Config <| |>

  #TODO
  # If tomcat service user is different from the build account
  # then also manage ssh key and private key for the tomcat user
  if $tomcat['user'] != $user_account['user'] {
    fail('Not Yet Implemented for situation where service user != account user')
  }
}
