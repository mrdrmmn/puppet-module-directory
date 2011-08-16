define directory (
  $path    = '',
  $recurse = false,
  $inherit = false,
  $owner   = undef,
  $group   = undef,
  $ensure  = "present",
  $mode    = undef
) {
  # If you want to allow removals to recurse downward, change
  # $remove_down to be true.
  $remove_down = false

  $config_path = $path ? {
    ''      => $name,
    default => $path
  }

  # Unset the 'File' and 'Directory defaults to ensure we don't break things!
  File{
    ensure  => undef,
    owner   => undef,
    group   => undef,
    mode    => undef,
    content => undef,
  }
  Directory{
    ensure  => undef,
    recurse => undef,
    inherit => undef,
    owner   => undef,
    group   => undef,
    mode    => undef,
  }

  # Do some sanity checking
  if( ! $config_path ) {
    fail( "'$config_path' is nat a valid directory path" )
  }

  $parent = inline_template( '<%= config_path.split("/").slice(0 .. -2).join("/") %>' )
  case $ensure {
    'present': {
      $file_ensure = 'directory'
    }
    'absent','purged': {
      $file_ensure = 'absent'
    }
    default: {
      fail( "'$ensure' is not a valid value for 'ensure'" )
    }
  }
        
  if( ! defined( File[ $config_path ] ) ) {
    @file { $config_path: ensure => $file_ensure }
    if( $owner   != '' ) { File[ $config_path ] { owner +> $owner     } }
    if( $group   != '' ) { File[ $config_path ] { group +> $owner     } }
    if( $mode ) { File[ $config_path ] { mode  +> $mode      } }
    if( $ensure != "present" ) {
      # This shit is janky, but puppet refuses to even attempt to remove
      # a directory unless you force it and then it is guaranteed to
      # remove it's contents.  Maybe I want it to fail if the directory
      # is not empty.  Sigh...
      File[ $config_path ] { force => true }
    }
    if( $parent != "" and ( $recurse == 'true' or $recurse == true ) and ( $ensure == "present" or $remove_down == 'true' or $remove_down == true ) ) {
      debug( 'recursively creating $parent' )
      if( ! defined( Directory[ $parent ] ) and $recurse != false ) {
        directory { $parent:
          path    => $parent,
          recurse => $recurse,
          ensure  => $ensure
        }
        if( $inherit == 'true' or $inherit == true ) {
          Directory[ $parent ] {
            owner   +> $owner,
            group   +> $group,
            mode    +> $mode,
            inherit +> $inherit,
          }
        }
        realize Directory[ $parent ]
      }
    }
    realize File[ $config_path ]
  }
}
