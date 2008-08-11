# bind module -- enhanced nameservice
# Copyright (c) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

import "zone.pp"

modules_dir { [ "bind", "bind/zones", "bind/options.d" ]: }

class bind {
	
	package { [ "bind9", "dnsutils" ]: ensure => installed }

	# The nameserver should run
	service { "bind9":
		ensure => running,
		pattern => named,
		subscribe => Exec["concat_/etc/bind/named.conf.local"]
	}

	nagios2::service { "check_dns": }

	config_file { "/etc/bind/named.conf.options":
		content => template( "bind/named.conf.options.erb"),
		notify => Service["bind9"]
	}

	concatenated_file {
		"/etc/bind/named.conf.local":
			dir => "/var/lib/puppet/modules/bind/options.d",
	}
	
	concatenated_file_part {
		legacy_include:
			dir => "/var/lib/puppet/modules/bind/options.d",
			content => "include \"/var/local/puppet/bind/edv-bus/config/master.conf\";\n",
	}

	Config_file <<| tag == 'bind' |>>
}

# use $domain if namevar is needed for disabiguation
define nagios::check_domain($domain = '', $record_type = 'SOA', $expected_address = '',
		$target_host = $fqdn)
{
	$diggit = $domain ? {
		'' => $name,
		default => $domain
	}

	$real_name = "check_dig3_${diggit}_${record_type}"
	if $bind_bindaddress {
		nagios2::service{ $real_name:
			check_command => "check_dig3!$diggit!$record_type!$bind_bindaddress!$expected_address",
			nagios2_host_name => $target_host,
		}
	} else {
		nagios2::service{ $real_name:
			check_command => "check_dig2!$diggit!$record_type!$expected_address",
			nagios2_host_name => $target_host,
		}
	}
}

