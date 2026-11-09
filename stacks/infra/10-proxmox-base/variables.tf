variable "bridge" {
  description = "Physical Linux bridge of the nodes, the uplink every VLAN zone sits on, e.g. vmbr0."
  type        = string
  nullable    = false
}

variable "native_vlan" {
  description = "VLAN of global-data/ipam.yaml carried untagged on the bridge; its VMs attach to the bridge itself."
  type        = string
  nullable    = false
}
