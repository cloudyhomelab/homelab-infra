import json
import re

from ansible.errors import AnsibleFilterError
from ansible.module_utils.common.text.formatters import human_to_bytes

# app and dataset become ZFS and filesystem path segments
SEGMENT = re.compile(r"^[A-Za-z0-9_-][A-Za-z0-9._-]*$")


def storage_exports(catalog, vms, addresses):
    """One export per (app, dataset) named by the images of the given VMs.

    catalog: the image catalog's `latest` output, keyed by <os>/<type>.
    vms: the domain's vms.yaml, {defaults, vms: key => {image, dhcp, ip4_address_cidr?, ...}}.
    addresses: VM key => {ip4_address_cidr, ...} reserved ahead of the VMs; empty in a domain without
    reservations, whose VMs pin ip4_address_cidr in vms.yaml.
    Returns [{app, dataset, recordsize?, hosts, images}] sorted by app and dataset, hosts as sorted
    addresses, images as sorted image names.
    """
    exports = {}
    first_image = {}
    for vm_key, settings in vms["vms"].items():
        vm = {**vms.get("defaults", {}), **settings}
        image = vm["image"]
        if image not in catalog:
            raise AnsibleFilterError(f"VM {vm_key}: image {image} is not in the catalog")
        storage = catalog[image].get("storage") or []
        if not storage:
            continue
        host = _host(vm_key, vm, addresses)
        for entry in storage:
            key = (entry["app"], entry["dataset"])
            for segment in key:
                if not SEGMENT.match(segment):
                    raise AnsibleFilterError(f"image {image}: invalid storage name {segment!r}")

            export = {"app": key[0], "dataset": key[1], "hosts": [], "images": []}
            if "recordsize" in entry:
                export["recordsize"] = entry["recordsize"]
            known = exports.setdefault(key, export)
            # Images sharing a dataset must agree on its properties, or each run would flip them
            if known.get("recordsize") != export.get("recordsize"):
                raise AnsibleFilterError(
                    f"{key[0]}/{key[1]}: {image} and {first_image[key]} want different recordsize"
                )
            first_image.setdefault(key, image)
            known["hosts"] = sorted({*known["hosts"], host})
            known["images"] = sorted({*known["images"], catalog[image]["type"]})

    return [exports[key] for key in sorted(exports)]


def _host(key, vm, addresses):
    # By address, never by name: the NFS server resolves a name only when it loads the exports, so a
    # record added later stays unseen until mountd restarts
    if vm["dhcp"]:
        raise AnsibleFilterError(f"VM {key}: a DHCP VM cannot use storage, which is shared by address")
    if key in addresses:
        return addresses[key]["ip4_address_cidr"].split("/")[0]
    if vm.get("ip4_address_cidr"):
        return vm["ip4_address_cidr"].split("/")[0]
    raise AnsibleFilterError(f"VM {key}: no address reserved; apply the domain's 16-vm-addresses first")


def recordsize_update(dataset_query, recordsize):
    """The recordsize to pass to arensb.truenas.filesystem, or None when the dataset already has it.

    The module compares the requested value (e.g. 32K) as text against the raw byte count (32768),
    so it reports a change on every run; the middleware accepts only the suffixed form, so bytes
    cannot be passed instead.
    """
    if recordsize is None:
        return None
    datasets = json.loads(dataset_query)
    if not datasets:
        return recordsize
    current = int(datasets[0]["recordsize"]["rawvalue"])
    wanted = human_to_bytes(recordsize)
    return None if current == wanted else recordsize


def merged_comment(share_query, images):
    """The share's comment as a ", "-joined list of image names: those already listed, plus the missing given ones."""
    shares = _single_share(share_query)
    current = [name for name in shares[0]["comment"].split(", ") if name] if shares else []
    return ", ".join(current + [name for name in images if name not in current])


def merged_hosts(share_query, hosts):
    """Hosts already allowed on the share, given as a `sharing.nfs.query` JSON result, plus the missing given ones."""
    shares = _single_share(share_query)
    current = shares[0]["hosts"] if shares else []
    return current + [host for host in hosts if host not in current]


def _single_share(share_query):
    shares = json.loads(share_query)
    if len(shares) > 1:
        raise AnsibleFilterError(f"{len(shares)} shares match one path")
    return shares


class FilterModule:
    def filters(self):
        return {
            "storage_exports": storage_exports,
            "merged_comment": merged_comment,
            "merged_hosts": merged_hosts,
            "recordsize_update": recordsize_update,
        }
