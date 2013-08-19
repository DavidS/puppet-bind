# Manage the Bind nameserver
# This module contains classes for a default installation with external zone file management as well as defines to build zones from
# collected resources

class bind (
  $ensure     = 'present',
  $version    = undef,
  $audit      = undef,
  $noop       = undef,
  # $install    = 'package',
  # $install_base_url           = undef,
  # $install_source             = undef,
  # $install_destination        = undef,
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
  $service_subscribe          = Class['bind::configuration'],
  $service_provider           = undef,
  $init_script_file           = '/etc/init.d/bind9',
  $init_script_file_template  = undef,
  $init_options_file          = $bind::params::init_options_file,
  $init_options_file_template = 'bind/init_options.erb',
  $config_file                = $bind::params::config_file,
  $config_file_owner          = 'root',
  $config_file_group          = 'root',
  $config_file_mode           = '0644',
  $config_file_replace        = true,
  $config_file_source         = undef,
  $config_file_template       = undef,
  $config_file_content        = undef,
  $config_file_options_hash   = undef,
  $dir        = $bind::params::dir,
  $dir_source = undef,
  $dir_purge  = false,
  $dir_recurse                = true,
  $zones_dir  = undef,
  $dependency_class           = 'bind::dependencies',
  $monitor_class              = 'bind::monitor',
  $firewall_class             = 'bind::firewall',
  $my_class   = undef,
  $monitor    = false,
  $monitor_host               = $::ipaddress,
  $monitor_port               = 53,
  $monitor_protocol           = both,
  $monitor_tool               = '',
  $firewall   = false,
  $firewall_src               = '0/0',
  $firewall_dst               = '0/0',
  $firewall_port              = 53,
  $firewall_protocol          = both) inherits bind::params {
  # Input parameters validation
  validate_re($bind::ensure, ['present', 'absent'], 'Valid values are: present, absent. WARNING: If set to absent all the resources managed by the module are removed.'
  )
  # validate_re($bind::install, ['package', 'upstream'], 'Valid values are: package, upstream.')
  validate_bool($bind::service_enable)
  validate_bool($bind::dir_recurse)
  validate_bool($bind::dir_purge)

  if $bind::version {
    $managed_package_ensure = $bind::version
  } else {
    $managed_package_ensure = $bind::ensure
  }

  if $bind::ensure == 'absent' {
    $managed_service_ensure = stopped
    $managed_service_enable = undef
    $dir_ensure = absent
    $config_file_ensure = absent
  } else {
    $managed_service_ensure = $bind::service_ensure
    $managed_service_enable = $bind::service_enable
    $dir_ensure = directory
    $config_file_ensure = present
  }

  $managed_service_provider = undef
  #  $bind::install ? {
  #    /(?i:upstream|puppi)/ => 'init',
  #    default               => undef,
  #  }


  $managed_dir = $bind::dir

  #   $bind::dir ? {
  #    ''      => $bind::install ? {
  #      package => $bind::dir,
  #      default => "${elasticsearch::home_dir}/config/",
  #    },
  #    default => $bind::dir,
  #  }

  $managed_zones_dir = pick($bind::zones_dir, "${bind::dir}/zones")

  # Resources Managed
  class {
    'bind::installation':
    ;

    'bind::configuration':
      require => Class['bind::installation'];

    'bind::service':
      require => Class['bind::configuration']; # see also $service_subscribe
  }

  # Extra classes
  if $bind::dependency_class {
    include $bind::dependency_class
  }

  if $bind::monitor and $bind::monitor_class {
    include $bind::monitor_class
  }

  if $bind::firewall and $bind::firewall_class {
    include $bind::firewall_class
  }

  if $bind::my_class {
    include $bind::my_class
  }
  #
  #  nagios::service { "check_dns": }
  #
  #  config_file { "/etc/bind/named.conf.options":
  #    content => template("bind/named.conf.options.erb"),
  #    notify  => Service["bind9"]
  #  }
  #
  #  concatenated_file { "/etc/bind/named.conf.local": dir => "${module_dir_path}/bind/options.d", }
  #
  #  concatenated_file_part { legacy_include:
  #    dir     => "${module_dir_path}/bind/options.d",
  #    content => "include \"/var/local/puppet/bind/edv-bus/config/master.conf\";\n",
  #  }
  #
  #  Config_file <<| tag == 'bind' |>>
}
#
# # use $domain if namevar is needed for disabiguation
# define nagios::check_domain ($domain = '', $record_type = 'SOA', $expected_address = '', $target_host = $fqdn) {
#  $diggit = $domain ? {
#    ''      => $name,
#    default => $domain
#  }
#
#  $real_name = "check_dig3_${diggit}_${record_type}"
#
#  if $bind_bindaddress {
#    nagios::service { $real_name:
#      check_command    => "check_dig3!$diggit!$record_type!$bind_bindaddress!$expected_address",
#      nagios_host_name => $target_host,
#    }
#  } else {
#    nagios::service { $real_name:
#      check_command    => "check_dig2!$diggit!$record_type!$expected_address",
#      nagios_host_name => $target_host,
#    }
#  }
#}
