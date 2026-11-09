locals {
  preinstalled_apt_repositories = ["enterprise", "ceph-squid-enterprise"]

  ipam = yamldecode(file("${path.module}/../../../global-data/ipam.yaml"))

  sdn_vnets = {
    for group, vlans in local.ipam.vlan_groups : group => {
      for name, vlan in vlans : name => vlan.vid if vlan.sdn
    }
  }

  sdn_zones = { for group, vnets in local.sdn_vnets : group => vnets if length(vnets) > 0 }
}
