# bind/manifests/zone.pp - manage a bind zone (file)
# Copyright (c) 2008 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

# $zone_conf_d = "${module_dir_path}/bind/zone/conf.d"

# # include this class to collect and configure all defined zones
# class bind::master {
#
# module_dir { [ "bind/zone", "bind/zone/conf.d", "bind/zone/contents", "bind/zone/contents.d" ]: }
#
# include bind
#
# Concatenated_file <<| tag == 'bind::master' |>>
# Concatenated_file_part <<| tag == 'bind::master' |>>
#
# concatenated_file {
# 	"${module_dir_path}/bind/zone/zone_list.conf":
# 		dir => $zone_conf_d;
#}
#
# concatenated_file_part {
# 	include_master_zones:
# 		dir => "${module_dir_path}/bind/options.d",
# 		content => "include \"${module_dir_path}/bind/zone/zone_list.conf\";\n",
#}
#
#
#}

# Define a DNS zone within bind.
# [*name*] The name of the dns zone
# [*ensure*] present or absent
# [*content*], [*template*], [*source*] the usual parameters to specify the contents of the zone
define bind::zone ($ensure = 'present', $content, $template, $source) {
  include bind

  $file = "${bind::managed_zones_dir}/${name}"

  file { $file:
    ensure => $bind::ensure,
    mode   => $bind::config_file_mode,
    owner  => $bind::config_file_owner,
    group  => $bind::config_file_group,
  }

  if $content {
    File[$file] {
      content => $content }
  }

  if $template {
    File[$file] {
      content => template($template) }
  }

  if $source {
    File[$file] {
      source => $source }
  }
}