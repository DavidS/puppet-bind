# bind/manifests/zone.pp - manage a bind zone (file)
# Copyright (c) 2008 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

$zone_conf_d = "/var/lib/puppet/modules/bind/zone/conf.d"

# include this class to collect and configure all defined zones
class bind::master {
	modules_dir { [ "bind/zone", "bind/zone/conf.d", "bind/zone/contents", "bind/zone/contents.d" ]: }
	include bind

	# todo: fix this!
	# Concatenated_file <<| tag == 'bind::master' |>>
	# Concatenated_file_part <<| tag == 'bind::master' |>>

	Concatenated_file <<| |>>
	Concatenated_file_part <<| |>>

	concatenated_file {
		"/var/lib/puppet/modules/bind/zone/zone_list.conf":
			dir => $zone_conf_d;
	}

	concatenated_file_part {
		include_master_zones:
			dir => "/var/lib/puppet/modules/bind/options.d",
			content => "include \"/var/lib/puppet/modules/bind/zone/zone_list.conf\";\n",
	}


}

# top-level define for a DNS zone. Use this to export the basic structures to
# your bind::master
define bind::zone($ensure = 'present') {

	case $ensure {
		'present': {
			$zone_file = "/var/lib/puppet/modules/bind/zone/contents/${name}"
			$zone_contents_d = "/var/lib/puppet/modules/bind/zone/contents.d/${name}"
			
			# create the infrastructure for receiving parts of the zone
			err("Tagging $zone_file: bind::master")
			@@concatenated_file {
				$zone_file:
					dir => $zone_contents_d,
					tag => 'bind::master';
			}
		
			# add the zone to the list of active zones
			@@concatenated_file_part {
				"zone_conf_${name}":
					dir => $zone_conf_d,
					content => "zone \"${name}\" { type master; file \"${zone_file}\"; };\n",
					tag => 'bind::master';
			}
		}
		'absent': {}
	}

}

# the namevar is for informational purposes only
define bind::rr2($rrname, $domain, $type, $ttl = '', $data)
{
	$fqrrname = $rrname ? { '' => "${domain}.", default => "${rrname}.${domain}." }
	$zone_contents_d = "/var/lib/puppet/modules/bind/zone/contents.d/${domain}"

	$order = $type ? { soa => '00', default => '50' }

	case $data {
		'': { fail("no data given for rr") }
	}

	@@concatenated_file_part {
		"${order}_${fqrrname}_${fqdn}_${name}":
			dir => $zone_contents_d,
			content => "${fqrrname} ${ttl} ${type} ${data}\n",
			tag => 'bind::master';
	}
}

# specify the SOA record
# since there can only be one per domain,
# using the domain-name as namevar is fine.
define bind::soa2(
	$rrname = '',
	$primary, $hostmaster, $serial,
	$ttl = '',
	$refresh = 7200, $retry = 3600, $expire = 604800, $minimum = 600)
{
	
	bind::rr2{
		"${name}_SOA":
			rrname => $rrname,
			domain => $name,
			type => 'SOA',
			ttl => $ttl,
			data => "${primary}. ${hostmaster}. ( ${serial} ${refresh} ${retry} ${expire} ${minimum} )",
	}

}

# namevar should contain ${rrname}, ${domain} and ${nsname}
define bind::ns2($rrname = '', $domain, $nsname, $ttl = '') {

	bind::rr2{
		"${name}_NS":
			rrname => $rrname,
			domain => $domain,
			type => 'NS',
			ttl => $ttl,
			data => "${nsname}.",
	}

}

# namevar should contain ${rrname}, ${domain} and ${mx}
define bind::mx2($rrname, $domain, $priority, $mx, $ttl = '') {

	bind::rr2{
		"${name}_MX":
			rrname => $rrname,
			domain => $domain,
			type => 'MX',
			ttl => $ttl,
			data => "${priority} ${mx}.",
	}

}

# namevar should contain ${rrname}, ${domain} and ${ip}
define bind::a2($rrname, $domain, $ip, $ttl = '') {

	bind::rr2{
		"${name}_A":
			rrname => $rrname,
			domain => $domain,
			type => 'A',
			ttl => $ttl,
			data => $ip,
	}

}

# namevar should contain ${rrname} and ${domain}, since there can only be one
# CNAME on a rrname
define bind::cname2($rrname, $domain, $cname, $ttl = '') {

	bind::rr2{
		"${name}_CNAME":
			rrname => $rrname,
			domain => $domain,
			type => 'CNAME',
			ttl => $ttl,
			data => "${cname}.",
	}

}



