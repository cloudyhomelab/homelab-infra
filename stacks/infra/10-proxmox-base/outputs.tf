output "bridges" {
  description = "VLAN name => bridge a VM attaches to for it: the VNet of an sdn VLAN, the physical bridge for the native VLAN."
  value       = merge(module.proxmox_sdn.vnet_ids, { (var.native_vlan) = var.bridge })

  precondition {
    condition     = !try(local.vlans[var.native_vlan].sdn, true)
    error_message = "native_vlan ${var.native_vlan} must be a VLAN of global-data/ipam.yaml with sdn: false."
  }
}
