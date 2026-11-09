# Storage

Prepares the TrueNAS datasets and NFS shares that the domain's images need, so a VM finds its storage ready when it boots and no rebuild or wipe of the VM can delete the data.

```sh
just plan <domain>/17-storage    # check mode with diff
just apply <domain>/17-storage
```

Each domain's `17-storage` stack links this playbook; it takes the domain from the stack's path. It runs after the image catalog and before the VM stacks.

## Inputs

- `latest` output of `15-image-catalog`: each image's `storage` list, published by the image build as `{app, dataset, recordsize?}`.
- `../vms.yaml`: the domain's VMs with their image and network settings; the VM stacks read the same file.
- `dns_zone` from the inventory, to form the hostnames of VMs without a pinned address.

## Layout and access

- One dataset per `app` and `dataset` pair, at `<pool>/cloudyhome_app_data/<app>/<dataset>`. Datasets belong to images, not VMs, and the path is lab-wide: images naming the same pair share the dataset and must agree on its `recordsize`.
- One NFS share per dataset, commented with the names of the images using it, allowing only the VMs whose image names it (no networks), with root mapped to `root`. A VM with `ip4_address_cidr` in `vms.yaml` is allowed by that address, since it may have no DNS record; any other VM (DHCP, or allocated by NetBox when it is created) by its hostname, which needs forward and reverse DNS records.
- `recordsize` is compared in the playbook (`recordsize_update` filter), because `arensb.truenas.filesystem` compares it as text against the raw byte count while the middleware accepts only the suffixed form.

## Never removes

- Datasets are never destroyed by tooling; `just destroy` refuses Ansible stacks. Deleting a dataset is a manual step.
- Each domain only adds its own VMs' hosts to a share's host list and its images' names to the share's comment, so domains sharing a dataset do not overwrite each other. Dropping a stale host is a manual step; until then, a new VM reusing that name or address gets access.

## Filter tests

```sh
python -m venv .venv && source .venv/bin/activate && pip install pytest ansible-core
cd ansible && pytest
```
