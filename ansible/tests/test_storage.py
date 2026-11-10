import json

import pytest
from ansible.errors import AnsibleFilterError

from storage import merged_comment, merged_hosts, recordsize_update, storage_exports

CATALOG = {
    "debian/app": {
        "type": "app",
        "storage": [
            {"app": "web", "dataset": "db", "recordsize": "32K"},
            {"app": "web", "dataset": "data"},
        ]
    },
    "debian/plain": {"type": "plain", "storage": []},
    "debian/old": {"type": "old"},
}


def domain(vms, defaults=None):
    """A vms.yaml document; a VM given as a string is a static VM with that image."""
    return {
        "defaults": defaults or {"dhcp": False},
        "vms": {key: {"image": vm} if isinstance(vm, str) else vm for key, vm in vms.items()},
    }


def reserved(**addresses):
    return {key: {"ip4_address_cidr": cidr, "gateway": "10.0.0.1", "dns_addresses": []} for key, cidr in addresses.items()}


def test_exports_per_dataset_with_hosts():
    vms = domain({"vm1": "debian/app", "vm0": "debian/app"})

    exports = storage_exports(CATALOG, vms, reserved(vm0="10.0.0.20/24", vm1="10.0.0.3/24"))

    assert exports == [
        {"app": "web", "dataset": "data", "hosts": ["10.0.0.20", "10.0.0.3"], "images": ["app"]},
        {
            "app": "web",
            "dataset": "db",
            "recordsize": "32K",
            "hosts": ["10.0.0.20", "10.0.0.3"],
            "images": ["app"],
        },
    ]


def test_reserved_address_wins_over_vms_yaml():
    vms = domain({"vm1": {"image": "debian/app", "ip4_address_cidr": "10.0.0.5/24"}})

    assert storage_exports(CATALOG, vms, reserved(vm1="10.0.0.6/24"))[0]["hosts"] == ["10.0.0.6"]


def test_pinned_vm_without_reservation_uses_its_address():
    vms = domain({"vm1": {"image": "debian/app", "ip4_address_cidr": "10.0.0.5/24"}})

    assert storage_exports(CATALOG, vms, {})[0]["hosts"] == ["10.0.0.5"]


def test_unreserved_vm_fails():
    with pytest.raises(AnsibleFilterError, match="no address reserved"):
        storage_exports(CATALOG, domain({"vm1": "debian/app"}), {})


def test_dhcp_vm_with_storage_fails():
    vms = domain({"vm1": {"image": "debian/app", "dhcp": True}})

    with pytest.raises(AnsibleFilterError, match="DHCP"):
        storage_exports(CATALOG, vms, {})


def test_vms_without_storage_need_no_address():
    vms = domain({"a": "debian/plain", "b": "debian/old", "c": {"image": "debian/plain", "dhcp": True}})

    assert storage_exports(CATALOG, vms, {}) == []


def test_vm_settings_override_defaults():
    vms = domain({"vm1": {"image": "debian/app", "dhcp": True}}, defaults={"dhcp": False})

    with pytest.raises(AnsibleFilterError, match="DHCP"):
        storage_exports(CATALOG, vms, reserved(vm1="10.0.0.5/24"))


def test_images_sharing_a_dataset_share_the_export():
    catalog = {**CATALOG, "debian/other": {"type": "other", "storage": [{"app": "web", "dataset": "data"}]}}
    vms = domain({"vm1": "debian/app", "vm2": "debian/other"})

    exports = storage_exports(catalog, vms, reserved(vm1="10.0.0.1/24", vm2="10.0.0.2/24"))

    data = next(e for e in exports if e["dataset"] == "data")
    assert data["hosts"] == ["10.0.0.1", "10.0.0.2"]
    assert data["images"] == ["app", "other"]


def test_conflicting_recordsize_fails():
    catalog = {**CATALOG, "debian/other": {"type": "other", "storage": [{"app": "web", "dataset": "db", "recordsize": "1M"}]}}
    vms = domain({"vm1": "debian/app", "vm2": "debian/other"})

    with pytest.raises(AnsibleFilterError, match="recordsize"):
        storage_exports(catalog, vms, reserved(vm1="10.0.0.1/24", vm2="10.0.0.2/24"))


def test_unknown_image_fails():
    with pytest.raises(AnsibleFilterError, match="not in the catalog"):
        storage_exports(CATALOG, domain({"vm1": "debian/missing"}), {})


@pytest.mark.parametrize("name", ["..", ".", "a/b", "", ".hidden"])
def test_unsafe_names_fail(name):
    catalog = {"debian/bad": {"type": "bad", "storage": [{"app": name, "dataset": "data"}]}}

    with pytest.raises(AnsibleFilterError, match="invalid storage name"):
        storage_exports(catalog, domain({"vm1": "debian/bad"}), reserved(vm1="10.0.0.1/24"))


def test_merged_hosts_keeps_current_and_adds_missing():
    query = json.dumps([{"path": "/mnt/p/x", "hosts": ["other.lab.example", "vm1.lab.example"]}])

    assert merged_hosts(query, ["vm1.lab.example", "vm2.lab.example"]) == [
        "other.lab.example",
        "vm1.lab.example",
        "vm2.lab.example",
    ]


def test_merged_hosts_for_a_new_share():
    assert merged_hosts("[]", ["vm1.lab.example"]) == ["vm1.lab.example"]


def test_merged_hosts_fails_on_ambiguous_path():
    with pytest.raises(AnsibleFilterError, match="2 shares"):
        merged_hosts(json.dumps([{"hosts": []}, {"hosts": []}]), [])


def dataset_query(rawvalue):
    return json.dumps([{"id": "p/x", "recordsize": {"rawvalue": rawvalue, "value": "?"}}])


@pytest.mark.parametrize(("raw", "wanted"), [("32768", "32K"), ("1048576", "1M"), ("512", "512")])
def test_recordsize_already_set_gives_none(raw, wanted):
    assert recordsize_update(dataset_query(raw), wanted) is None


def test_recordsize_differs_gives_wanted():
    assert recordsize_update(dataset_query("131072"), "32K") == "32K"


def test_recordsize_for_a_new_dataset():
    assert recordsize_update("[]", "1M") == "1M"


def test_recordsize_not_requested():
    assert recordsize_update(dataset_query("131072"), None) is None


def share_query(comment):
    return json.dumps([{"path": "/mnt/p/x", "comment": comment, "hosts": []}])


def test_merged_comment_keeps_current_and_adds_missing():
    assert merged_comment(share_query("other, app"), ["app", "third"]) == "other, app, third"


def test_merged_comment_replaces_an_empty_comment():
    assert merged_comment(share_query(""), ["app"]) == "app"


def test_merged_comment_for_a_new_share():
    assert merged_comment("[]", ["app", "other"]) == "app, other"
