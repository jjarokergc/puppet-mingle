# Create accounts to build  mingle
#
class profile::mingle::accounts {
  # Mingle Build Variables
  $b = lookup('mingle::build')
  $s = lookup('mingle::server')

  $user_account = $b['account']
  $tomcat = $s['tomcat']

  ### Mingle user account for code checkout and build
  if ! defined(Accounts::User[$user_account['user']]) {
    accounts::user { $user_account['user']:
      comment  => $user_account['comment'],
      password => '!!',
      shell    => '/bin/bash',
    }
  }

  ### Service Account to run tomcat
  if ! defined(Accounts::User[$tomcat['user']]) {
    accounts::user { $tomcat['user']:
      comment  => $tomcat['comment'],
      password => '!!',
      shell    => '/bin/bash',
    }
  }
}
