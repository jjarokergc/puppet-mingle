# Install highcharts for Mingle
class mingle::highcharts {
  $b = lookup('mingle::build')    # Parameters located in hiera
  $h = $b['highcharts']           # Highchart build parameters hash
  $m = $b['account']              # Mingle account details

  # Highchart Build File Parameters
  $cwd = "${h['path']}/${h['name']}"                 # ex: /opt/apps/highcharts-2.2.3
  $archive_name = "${h['name']}.${h['ext']}"         # ex: highcharts-2.2.3.zip
  $highcarts_artifact = "${cwd}/${h['ant_creates']}" # ex: /opt/apps/highcharts-2.2.3/build/dist/Highcharts-2.2.3.zip

  # Extract highcharts build to Mingle
  $mingle_dir="${m['homedir']}/${m['workspace']}"    #ex: /home/mingle/src
  $highcharts_path = "${mingle_dir}/${h['install_path']}"
  $highcharts_creates = "${highcharts_path}/${h['install_dir']}"

  # Build Highcharts. Produces archive.
  exec { 'Ant Build Highcharts':
    command => 'ant dist',
    cwd     => $cwd,
    creates => $highcarts_artifact,
    path    => ['/bin', '/usr/bin'],
    require => [
      Archive[$archive_name],
      Package['ant'],
    ],
  }

  # Extract archive created above to mingle javascripts
  archive { $highcarts_artifact:
    extract       => true,
    extract_path  => $highcharts_path,
    creates       => $highcharts_creates,
    extract_flags => "-o -d ${highcharts_creates}",
    cleanup       => false,
    require       => [
      Exec['Ant Build Highcharts'],
      Vcsrepo[$mingle_dir],
    ],
  }
}
