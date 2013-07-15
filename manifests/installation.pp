# manages the basic installation of bind 
class bind::installation {
  if $bind::package {
    package { $bind::package:
      ensure   => $bind::managed_package_ensure,
      provider => $bind::package_provider,
    }
  }
}