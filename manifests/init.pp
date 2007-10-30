# bind module -- enhanced nameservice
# copyright (c) 2007 david schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

modules_dir { [ "bind", "bind/options.d", "bind/domains", "bind/slaves"  ]: }

class bind {
	
	package { [ "bind9", "dnsutils" ]: ensure => installed }

	# The nameserver should run
	service { "bind9":
		ensure => running,
		pattern => named,
	}

	nagios2::service { "check_dns": }

	config_file { "/etc/bind/named.conf.options":
		content => template( "bind/named.conf.options.erb"),
		notify => Service["bind9"]
	}

	case $bind_type { 
		'master': {
			#@@config_file { "/var/lib/puppet/modules/bind/master/${bind_bindaddress}": content => "\n" }
		}
		'slave': {
			@@config_file { "/var/lib/puppet/modules/bind/slaves/${bind_bindaddress}": content => "\n" }
		}
	}
	File <<||>>
}

# use $domain if namevar is needed for disabiguation
define nagios2::check_dig2($domain = '', $record_type = 'A', $expected_address = '',
		$target_host = $fqdn)
{
	$diggit = $domain ? {
		'' => $name,
		default => $domain
	}

	$real_name = "check_dig2_${diggit}_${record_type}"
	nagios2::service{ $real_name:
		check_command => "check_dig2!$diggit!$record_type!$expected_address",
		nagios2_host_name => $target_host,
	}
}

