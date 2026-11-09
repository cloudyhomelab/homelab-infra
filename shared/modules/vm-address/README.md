# vm-address

Registers a VM's IPv4 address in NetBox and returns the network settings for it, all read from NetBox by the VLAN name:

- `ip4_address_cidr` set: registers that address; it must lie in the VLAN's prefix with the prefix's mask.
- `ip4_address_cidr` null: allocates the next free address from the prefix's one active IP range with role `static`.

The gateway and DNS servers come from the prefix's `gateway` (object) and `dns_servers` (multiobject) custom fields, which point at IP address records.

Outputs `ip4_address_cidr`, `gateway` and `dns_addresses`. The caller configures the `netbox` provider.

`dns_addresses` comes in the order NetBox lists the addresses, not the order the field was set in, so the field cannot express a primary DNS server.
