# Install files from a hash 'archive::files' using the 'archive' module
# Requires 
#   * archive module 
#   * wget package
# Loops across all repo definitions and all files within each repo
#   Outer loop: 'repo_url'
#   Innter loop: 'package_name'
class mingle::archive {
  include archive

  ### Variables
  $f = lookup('archive::files')    # Repo 'f' is a datastructure in hiera

  $f.each | $i, $v | {
    # For each Repository
    $repo = $v['repo_url']
    $user = $v['user']
    $password = $v['password']
    # Each repo can contain a list of files
    $files = $v['files']

    # For each File at this repo_url
    $files.each | $si, $s | {
      $package_name = $s['package_name']
      $package_ext = $s['package_ext']
      $repo_path = $s['repo_path']
      $install_path = $s['install_path']
      $creates = $s['creates']

      # Derived variables
      $extract = 'extract' in $s ? { # Extract files by default
        true  => $s['extract'],
        false => true,
      }
      $archive_name = "${package_name}.${package_ext}"
      $path = $extract ? { # Location to download file
        true  => "/tmp/${archive_name}",            # If extracting files, then download to /tmp
        false => "${install_path}/${archive_name}", # Otherwise, download file directly to final path
      }
      $source = "${repo}${repo_path}${archive_name}"
      $checksum = ($s['checksum'] =~ String[1]) ? {
        true    => $s['checksum'],
        default => '',
      }
      $checksum_type = ($s['checksum_type'] =~ String[1]) ? {
        true => $s['checksum_type'],
        default => 'none',
      }
      # If chown variable is specified, then call exec to change ownership
      $call_chown = ($s['chown'] =~ String[1])  # Match chown to a string of 1+ char
      # If symlink path exist, then create link
      $create_symlink = ($s['symlink']['path'] =~ String[1])

      # Create install directory if it does not exist
      exec { "Archive install path ${i} ${si}":
        command => "mkdir -p ${install_path}",
        #unless  => "test -e ${install_path}",
        creates => $install_path,
        path    => ['/bin', '/usr/bin'],
        before  => Archive[$archive_name],
      }

      # Download file
      archive { $archive_name:
        path          => $path,
        username      => $user,
        password      => $password,
        source        => $source,
        extract       => $extract,
        checksum_type => $checksum_type,
        checksum      => $checksum,
        extract_path  => $install_path,
        creates       => "${install_path}/${creates}",
        cleanup       => true,
      } # Download File

      # Change ownership of files
      if $call_chown {
        exec { "File Permissions ${i} ${si}":
          command     => "chown -R ${s['chown']} ${install_path}",
          path        => ['/bin', '/usr/bin'],
          refreshonly => true,
          subscribe   => Archive[$archive_name],
        }
      }

      # Create symlink
      if $create_symlink {
        file { "Symlink ${i} ${si}":
          ensure  => link,
          path    => $s['symlink']['path'],
          target  => $s['symlink']['target'],
          require => Archive[$archive_name],
        }
      } # Create Symlink
    } # For each file at this repo
  } # Process all Repos
}
