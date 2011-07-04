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
    $path    = $name,
    $recurse = false,
    $inherit = false,
    $owner   = undef,
    $group   = undef,
    $ensure  = "present",
    $require = undef,
    $mode    = ""
) {
    # If you want to allow removals to recurse downward, change
    # $remove_down to be true.
    $remove_down = false

    $parent = inline_template( '<%= path.split("/").slice(0 .. -2).join("/") %>' )
    case $ensure {
        present: { $file_ensure = "directory" }
        default: { $file_ensure = $ensure     }
    }
        
    if( ! defined( File[$path] ) ) {
        @file { $path: ensure => $file_ensure }
        if( $owner != ""   ) { File[$path] { owner +> $owner }     }
        if( $group != ""   ) { File[$path] { group +> $owner }     }
        if( $require != "" ) { File[$path] { require +> $require } }
        if( $ensure == "absent" ) {
            # This shit is janky, but puppet refuses to even attempt to remove
            # a directory unless you force it and the it is guaranteed to
            # remove it's contents.  Maybe I want it to fail if the directory
            # is not empty.  Sigh...
            File[$path] { force => true }
        }
        if( $parent != "" and $recurse == true and ( $ensure != "absent" or $remove_down == true ) ) {
            if( $ensure == "present" ) {
                File[$path] { require +> File[$parent] }
            }
            if( ! defined( Directory[$parent] ) and $recurse != false ) {
                directory { $parent: recurse => $recurse, ensure => $ensure }
                if( $ensure == "absent" ) {
                    Directory[$parent] { require => File[$path] }
                }
                if( $inherit == true ) {
                    Directory[$parent] {
                        owner   +> $owner,
                        group   +> $group,
                        mode    +> $mode,
                        inherit +> $inherit,
                    }
                }
                realize Directory[$parent]
            }
        }
        realize File[$path]
    }
}
