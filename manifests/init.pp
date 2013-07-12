# Manage the Bind nameserver
# This module contains classes for a default installation with external zone file management as well as defines to build zones from
# collected resources

class bind (
  $ensure     = 'present',
  $version    = undef,
  $audit      = undef,
  $noop       = undef,
  $install    = 'package',
  $install_base_url           = undef,
  $install_source             = undef,
  $install_destination        = undef,
  $user       = $bind::params::user,
  $user_create                = true,
  $user_uid   = undef,
  $user_gid   = undef,
  $user_groups                = undef,
  $package    = $bind::params::package,
  $package_provider           = undef,
  $service    = $bind::params::service,
  $service_ensure             = 'running',
  $service_enable             = true,
  $service_subscribe          = Class['bind::config'],
  $service_provider           = undef,
  $init_script_file           = '/etc/init.d/bind9',
  $init_script_file_template  = undef,
  $init_options_file          = $bind::params::init_options_file,
  $init_options_file_template = 'bind/init_options.erb',
  $config_path                = $bind::params::config_path,
  $config_owner               = 'root',
  $config_group               = 'root',
  $config_mode                = '0644',
  $config_replace             = true,
  $config_source              = undef,
  $config_template            = undef,
  $config_content             = undef,
  $config_options_hash        = undef,
  $dir        = $bind::params::dir,
  $dir_source = undef,
  $dir_purge  = false,
  $dir_recurse                = true,
  $dependency_class           = 'bind::dependency',
  $monitor_class              = 'bind::monitor',
  $firewall_class             = 'bind::firewall',
  $my_class   = undef,
  $monitor    = false,
  $monitor_host               = $::ipaddress,
  $monitor_port               = 9200,
  $monitor_protocol           = tcp,
  $monitor_tool               = '',
  $firewall   = false,
  $firewall_src               = '0/0',
  $firewall_dst               = '0/0',
  $firewall_port              = 53,
  $firewall_protocol          = both) {
  module_dir { ["bind", "bind/zones", "bind/options.d"]: }

  package { ["bind9", "dnsutils"]: ensure => installed }

  # The nameserver should run
  service { "bind9":
    ensure    => running,
    pattern   => named,
    subscribe => Exec["concat_/etc/bind/named.conf.local"]
  }

  nagios::service { "check_dns": }

  config_file { "/etc/bind/named.conf.options":
    content => template("bind/named.conf.options.erb"),
    notify  => Service["bind9"]
  }

  concatenated_file { "/etc/bind/named.conf.local": dir => "${module_dir_path}/bind/options.d", }

  concatenated_file_part { legacy_include:
    dir     => "${module_dir_path}/bind/options.d",
    content => "include \"/var/local/puppet/bind/edv-bus/config/master.conf\";\n",
  }

  Config_file <<| tag == 'bind' |>>
}

# use $domain if namevar is needed for disabiguation
define nagios::check_domain ($domain = '', $record_type = 'SOA', $expected_address = '', $target_host = $fqdn) {
  $diggit = $domain ? {
    ''      => $name,
    default => $domain
  }

  $real_name = "check_dig3_${diggit}_${record_type}"

  if $bind_bindaddress {
    nagios::service { $real_name:
      check_command    => "check_dig3!$diggit!$record_type!$bind_bindaddress!$expected_address",
      nagios_host_name => $target_host,
    }
  } else {
    nagios::service { $real_name:
      check_command    => "check_dig2!$diggit!$record_type!$expected_address",
      nagios_host_name => $target_host,
    }
  }
}

