# Install required packages for mingle build
#
class mingle::packages {
  include apt

  # VARIABLES
  $d = lookup('mingle::dependencies')
  $p = $d['packages']

  # Mingle build dependencies
  package { $p:    ensure => installed, } # ...defined in 'apt::packages'
}
