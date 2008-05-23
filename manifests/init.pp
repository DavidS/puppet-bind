# bind module -- enhanced nameservice
# Copyright (c) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

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

define bind::zone_file($ensure = 'present', $content = '', $source = '', $master = false, $public = true) {

	include bind

	if $master {
		if $public {
			debug("this space is intentionally left blank")
		}
		else {
			fail ("zone_file for ${name} is master, but not public!")
		}
	}

	$zone_file    = "/var/lib/puppet/modules/bind/zones/${name}"
	$rrs_dir      = "/var/lib/puppet/modules/bind/${name}/rrs"
	$zone_header  = "/var/lib/puppet/modules/bind/${name}/zoneheader"
	$content_file = "${rrs_dir}/content"
	$ns_type = $master ? {
		true  => "masters",
		false => "slaves",
	}
	$registration_file = "/var/lib/puppet/modules/bind/${name}/${ns_type}/${bind_bindaddress}"

	modules_dir {
		[ "bind/${name}", "bind/${name}/masters", "bind/${name}/slaves", "bind/${name}/rrs" ] :
			tag => 'bind'
		}
	
	@@config_file { $registration_file:
		ensure  => $ensure,
		content => "${bind_bindaddress};\n",
		tag => 'bind'
	}

	nagios::check_domain { $name: }

	if $master {

		# construct the zone file
		concatenated_file {
			$zone_file:
				dir => $rrs_dir,
				header => $zone_header,
				notify => Service["bind9"],
		}
		config_file { 
			$zone_header:
				content => "\$ORIGIN ${name}.\n\$TTL 86400\n\n",
				notify => Exec["concat_${zone_file}"];
			$content_file:
				ensure => $ensure,
				content => $content,
				source => $source,
				notify => Exec["concat_${zone_file}"]
		}

		concatenated_file_part {
			"zone_conf_${name}":
				dir => "/var/lib/puppet/modules/bind/options.d",
				content => "zone \"${name}\" { type master; file \"/var/lib/puppet/modules/bind/zones/${name}\"; };\n"
		}

	}
	else
	{

		$conf_header  = "/var/lib/puppet/modules/bind/${name}/confheader"
		$conf_footer  = "/var/lib/puppet/modules/bind/${name}/conffooter"
		$conf_file    = "/var/lib/puppet/modules/bind/options.d/zone_conf_${name}"
		config_file { 
			$conf_header:
				content => "zone \"${name}\" { type slave; file \"${name}\"; masters {\n",
				notify => Exec["concat_${conf_file}"];
			$conf_footer:
				content => "}; };\n",
				notify => Exec["concat_${conf_file}"];
		}
		concatenated_file {
			$conf_file:
				dir => "/var/lib/puppet/modules/bind/${name}/masters",
				header => $conf_header,
				footer => $conf_footer,
				notify => Exec["concat_/etc/bind/named.conf.local"]
		}

	}

}

define bind::soa(
	$primary, $hostmaster, $serial,
	$ensure = 'present',
	$refresh = 7200, $retry = 3600, $expire = 604800, $minimum = 600)
{
	$zone_file    = "/var/lib/puppet/modules/bind/zones/${name}"
	$rrs_dir      = "/var/lib/puppet/modules/bind/${name}/rrs"
	config_file {
		"${rrs_dir}/00_soa":
			ensure => $ensure,
			content => "${name}.		SOA ${primary} ${hostmaster} ( ${serial} ${refresh} ${retry} ${expire} ${minimum} )\n",
			notify => Exec["concat_${zone_file}"]
	}
}
define bind::rr(
	$domain,
	$ensure = 'present',
	$content)
{
	$zone_file    = "/var/lib/puppet/modules/bind/zones/${domain}"
	$rrs_dir      = "/var/lib/puppet/modules/bind/${domain}/rrs"
	config_file {
		"${rrs_dir}/${name}":
			ensure => $ensure,
			content => $content,
			notify => Exec["concat_${zone_file}"]
	}
}
