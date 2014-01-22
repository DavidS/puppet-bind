class bind::dependencies {
  # always handy
  if (!defined(Package["dnsutils"])) {
    package { 'dnsutils': ensure => installed; }
  }
}