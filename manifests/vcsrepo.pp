# Clones repositories from a hash 'vcsrepo::files' using the 'vcsrepo' module
# Requires 
#   * vcsrepo module 
#   * git module
# Loops across all repo definitions and all files within each repo
#   Outer loop: repo host
#   Innter loop: project
class profile::mingle::vcsrepo {
  ### Variables
  $r = lookup('vcsrepo::repos')    # Repo 'r' is a datastructure in hiera
  $b = lookup('mingle::build')
  $account = $b['account']

  $r.each | $ri, $rv | { #ri - index; rv - value
    $url = $rv['url']
    $repos = $rv['repos']

    $depth = 'depth' in $rv ? {
      true => $rv['depth'],
      false => undef,
    }

    $repos.each | $si, $sv | {
      $project = $sv['project'] # Git file, ex: mingle/server.git
      $path = $sv['path'] # Local path where to check out, ex: /opt/app
      $dir = $sv['dir']   # Directory name for checkout
      $branch = ($sv['branch'] =~ String[1]) ? {
        true    => $sv['branch'],
        default => undef,
      }

      # Derived variables
      $separator = $url ? {
        /^http/ => '/',   # http access
        /^git/ => ':',    # ssh access
      }
      $source_repo = "${url}${separator}${project}"  # Example git@gitlab.jaroker.org:puppet/jj-dokuwiki.git
      $workspace = "${path}/${dir}"

      # Create install directory if it does not exist
      exec { "VCSRepo Path ${ri} ${si}":
        command => "mkdir -p ${path}",
        #unless  => "test -e ${path}",
        creates => $path,
        path    => ['/bin', '/usr/bin'],
        before  => Vcsrepo[$workspace],
      }

      # Clone Repository 
      vcsrepo { $workspace:
        ensure     => present,
        provider   => 'git',
        source     => $source_repo,
        revision   => $branch,
        depth      => $depth,
        user       => $account['user'],
        submodules => false,
      } # Clone Repository
    } # For each file at this repo
  } # Process all Repos
}
