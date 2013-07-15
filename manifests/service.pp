# manage the bind daemon
class bind::service {
  if $bind::service {
    service { $bind::service:
      ensure    => $bind::managed_service_ensure,
      enable    => $bind::managed_service_enable,
      subscribe => $bind::service_subscribe,
      provider  => $bind::managed_service_provider,
    }
  }
}