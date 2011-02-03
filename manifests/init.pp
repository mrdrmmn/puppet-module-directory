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
define directory {
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

    $parent = inline_template( '<%= name.split("/").slice(0 .. -2).join("/") %>' )
    case $ensure {
        present: { $file_ensure = "directory" }
        default: { $file_ensure = $ensure     }
    }
        
    if( ! defined( File[$name] ) ) {
        @file { $name: ensure => $file_ensure }
        if( $owner != ""   ) { File[$name] { owner +> $owner }     }
        if( $group != ""   ) { File[$name] { group +> $owner }     }
        if( $require != "" ) { File[$name] { require +> $require } }
        if( $ensure == "absent" ) {
            # This shit is janky, but puppet refuses to even attempt to remove
            # a directory unless you force it and the it is guaranteed to
            # remove it's contents.  Maybe I want it to fail if the directory
            # is not empty.  Sigh...
            File[$name] { force => true }
        }
        if( $parent != "" and $recurse == true and ( $ensure != "absent" or $remove_down == true ) ) {
            if( $ensure == "present" ) {
                File[$name] { require +> File[$parent] }
            }
            if( ! defined( Directory[$parent] ) and $recurse != false ) {
                directory { $parent: recurse => $recurse, ensure => $ensure }
                if( $ensure == "absent" ) {
                    Directory[$parent] { require => File[$name] }
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
        realize File[$name]
    }
}
