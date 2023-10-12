# Install Mingle Database
# # Postgresql server or client is configured in Profile::Postgresql
# Create mingle databases and user
##
class mingle::database {
  # Variables
  $s = lookup('mingle::server') # Tomcat server parameters stored in Hiera
  $n = $s['instance']           # Mingle instance parameters

  $common_attributes = { # Postgresql Database Attributes
    'user'     => $n['db']['user'],
    'password' => $n['db']['password'],
    'comment'  => "Mingle ${n['environment']} database",
    'dbname'   => $n['db']['name'],
  }

  # Either install the database locally or on remote server
  if $n['db']['host'] == 'localhost' { # Postgresql server is installed locally
    postgresql::server::db { "Mingle DB ${n['environment']}": * => $common_attributes, }
  }
  else { # Postgres server is remote

    #Export database to remote Postgresql server
    @@postgresql::server::db { "Mingle DB ${n['environment']}": * => $common_attributes, }

    # Validate connection to remote Postgresql database before starting Mingle service
    # This appears in puppet agent messages as:
    # "Warning: PostgresqlValidator.attempt_connection: Sleeping for 2 seconds"
    # If provisioning both Mingle Server and remote Database Server, then 
    # run puppet agent in two passes: First time to export the database resource and the
    # second time to finish the setup after the Database Server applies this
    # exported resource to create the Mingle database
    postgresql_conn_validator { 'Validate Connection to Remote Mingle Database':
      host        => $n['db']['host'],
      db_username => $n['db']['user'],
      db_password => $n['db']['password'],
      db_name     => $n['db']['name'],
      psql_path   => '/usr/bin/psql',
    }
    -> Service['mingle']
  }
}
