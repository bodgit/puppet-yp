# Transforms a YP map name to the corresponding make target.
#
# @param maps Either a single map name or an array of map names.
#
# @return [Variant[String, Array[String, 1]]] Either a single make target or array of make targets.
#
# @example
#   yp::map_to_make_target(['group.byname', 'group.bygid'])
#   yp::map_to_make_target('passwd.byname')
#
# @since 2.0.0
function yp::map_to_make_target(Variant[String, Array[String, 1]] $maps) {

  $default = {
    '(?x) ^ master \. passwd \.'                        => 'passwd.',
    '(?x) (?: \. by[a-z]+ | (?<= mail ) \. aliases ) $' => '',
  }

  case $::osfamily {
    'OpenBSD': {
      $gsubs = $default + {
        '(?x) ^ mail $' => 'aliases',
      }
    }
    'RedHat': {
      $gsubs = $default + {
        '(?x) ^ netgroup $' => 'netgrp',
      }
    }
    default: {
      $gsubs = $default
    }
  }

  type($maps) ? {
    Type[Scalar] => $gsubs.reduce($maps) |$memo, $gsub| {
      regsubst($memo, $gsub[0], $gsub[1])
    },
    default      => unique($maps.map |$map| {
      $gsubs.reduce($map) |$memo, $gsub| {
        regsubst($memo, $gsub[0], $gsub[1])
      }
    }),
  }
}
