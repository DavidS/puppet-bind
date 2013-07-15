# manage all configuration files
class bind::configuration {
  if $bind::config_file {
    file { 'named.conf':
      ensure => $bind::config_file_ensure,
      path   => $bind::config_file,
      mode   => $bind::config_file_mode,
      owner  => $bind::config_file_owner,
      group  => $bind::config_file_group,
      source => $bind::config_file_source,
    }

    if $bind::config_file_content {
      File['named.conf'] {
        content => $bind::config_file_content }
    }

    if $bind::config_file_template {
      File['named.conf'] {
        content => template($bind::config_file_template) }
    }
  }

  # Configuration Directory, if dir is defined
  if $bind::dir_source {
    file { 'elasticsearch.dir':
      ensure  => $bind::dir_ensure,
      path    => $bind::managed_dir,
      source  => $bind::dir_source,
      recurse => $bind::dir_recurse,
      purge   => $bind::dir_purge,
      force   => $bind::dir_purge,
    }
  }

  if $bind::init_options_file {
    file { 'bind_defaults.conf':
      ensure => $bind::config_file_ensure,
      path   => $bind::init_options_file,
      mode   => $bind::config_file_mode,
      owner  => $bind::config_file_owner,
      group  => $bind::config_file_group,
    }

    if $bind::init_options_file_template {
      File['bind_defaults.conf'] {
        content => template($bind::init_options_file_template) }
    }
  }
}