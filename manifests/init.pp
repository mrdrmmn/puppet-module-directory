# Define: directory
#
# This module manages directory
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
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

  $parent = inline_template( '<%= config_path.split("/").slice(0 .. -2).join("/") %>' )
  case $ensure {
    present: { $file_ensure = "directory" }
    default: { $file_ensure = $ensure     }
  }
        
  if( ! defined( File[ $config_path ] ) ) {
    @file { $config_path: ensure => $file_ensure }
    if( $owner   != '' ) { File[ $config_path ] { owner +> $owner     } }
    if( $group   != '' ) { File[ $config_path ] { group +> $owner     } }
    if( $mode ) { File[ $config_path ] { mode  +> $mode      } }
    if( $ensure == "absent" ) {
      # This shit is janky, but puppet refuses to even attempt to remove
      # a directory unless you force it and then it is guaranteed to
      # remove it's contents.  Maybe I want it to fail if the directory
      # is not empty.  Sigh...
      File[ $config_path ] { force => true }
    }
    if( $parent != "" and ( $recurse == 'true' or $recurse == true ) and ( $ensure != "absent" or $remove_down == true ) ) {
      debug( 'recursively creating $parent' )
      if( ! defined( Directory[ $parent ] ) and $recurse != false ) {
        directory { $parent:
          path    => $parent,
          recurse => $recurse,
          ensure  => $ensure
        }
        if( $inherit == true ) {
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
