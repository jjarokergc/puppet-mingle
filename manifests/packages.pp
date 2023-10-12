# Install required packages for mingle build
class mingle::packages {
  include apt
  # Mingle build dependencies
  $p = lookup('apt::packages')
  package { $p:    ensure => installed, } # ...defined in 'apt::packages'
}
