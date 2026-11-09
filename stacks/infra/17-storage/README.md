# Storage

Prepares the TrueNAS datasets and NFS shares that the domain's images need, so a VM finds its storage ready when it boots and no rebuild or wipe of the VM can delete the data.

```sh
just plan infra/17-storage    # check mode with diff
just apply infra/17-storage
```

It runs after the image catalog and before the VM stacks.

## Inputs

- `latest` output of `15-image-catalog`: each image's `storage` list, published by the image build as `{app, dataset, recordsize?}`.
- `../vms.yaml`: VM name to image; the VM stacks read their image from the same file.
- `dns_zone` from the inventory, to form the VM hostnames.

## Layout and access

- One dataset per `app` and `dataset` pair, at `<pool>/cloudyhome_app_data/<app>/<dataset>`. Datasets belong to images, not VMs, and the path is lab-wide: images naming the same pair share the dataset and must agree on its `recordsize`.
- One NFS share per dataset, commented with the names of the images using it, allowing only the hostnames of the VMs whose image names it (no networks), with root mapped to `root`. The names need forward and reverse DNS records.
- `recordsize` is compared in the playbook (`recordsize_update` filter), because `arensb.truenas.filesystem` compares it as text against the raw byte count while the middleware accepts only the suffixed form.

## Never removes

- Datasets are never destroyed by tooling; `just destroy` refuses Ansible stacks. Deleting a dataset is a manual step.
- Each domain only adds its own VMs' hostnames to a share's host list and its images' names to the share's comment, so domains sharing a dataset do not overwrite each other. Dropping a stale hostname is a manual step; until then, a new VM reusing that name gets access.

## Filter tests

```sh
python -m venv .venv && source .venv/bin/activate && pip install pytest ansible-core
cd ansible && pytest
```
