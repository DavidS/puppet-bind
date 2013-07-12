class bind::params {
  $user = $::osfamily ? {
    default => 'bind',
  }

  $package = $::osfamily ? {
    default => 'bind9',
  }

  $service = $::osfamily ? {
    default => 'bind9',
  }

  $init_options_file = $::osfamily ? {
    Debian  => '/etc/default/bind9',
    default => '/etc/sysconfig/bind9',
  }

  $config_path = $::osfamily ? {
    default => '/etc/bind9/named.conf'
  }

  $dir = $::osfamily ? {
    default => '/etc/bind9/',
  } }