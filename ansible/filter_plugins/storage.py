import json
import re

from ansible.errors import AnsibleFilterError
from ansible.module_utils.common.text.formatters import human_to_bytes

# app and dataset become ZFS and filesystem path segments
SEGMENT = re.compile(r"^[A-Za-z0-9_-][A-Za-z0-9._-]*$")


def storage_exports(catalog, vms, zone):
    """One export per (app, dataset) named by the images of the given VMs.

    catalog: the image catalog's `latest` output, keyed by <os>/<type>.
    vms: VM name => catalog key.
    Returns [{app, dataset, recordsize?, hosts}] sorted by app and dataset, hosts as sorted FQDNs.
    """
    if not zone:
        raise AnsibleFilterError("zone is empty")

    exports = {}
    first_image = {}
    for vm, image in vms.items():
        if image not in catalog:
            raise AnsibleFilterError(f"VM {vm}: image {image} is not in the catalog")
        for entry in catalog[image].get("storage") or []:
            key = (entry["app"], entry["dataset"])
            for segment in key:
                if not SEGMENT.match(segment):
                    raise AnsibleFilterError(f"image {image}: invalid storage name {segment!r}")

            export = {"app": key[0], "dataset": key[1], "hosts": []}
            if "recordsize" in entry:
                export["recordsize"] = entry["recordsize"]
            known = exports.setdefault(key, export)
            # Images sharing a dataset must agree on its properties, or each run would flip them
            if known.get("recordsize") != export.get("recordsize"):
                raise AnsibleFilterError(
                    f"{key[0]}/{key[1]}: {image} and {first_image[key]} want different recordsize"
                )
            first_image.setdefault(key, image)
            known["hosts"] = sorted({*known["hosts"], f"{vm}.{zone}"})

    return [exports[key] for key in sorted(exports)]


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


def merged_hosts(share_query, hosts):
    """Hosts already allowed on the share, given as a `sharing.nfs.query` JSON result, plus the missing given ones."""
    shares = json.loads(share_query)
    if len(shares) > 1:
        raise AnsibleFilterError(f"{len(shares)} shares match one path")
    current = shares[0]["hosts"] if shares else []
    return current + [host for host in hosts if host not in current]


class FilterModule:
    def filters(self):
        return {
            "storage_exports": storage_exports,
            "merged_hosts": merged_hosts,
            "recordsize_update": recordsize_update,
        }
