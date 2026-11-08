import json

import pytest
from ansible.errors import AnsibleFilterError

from storage import merged_hosts, recordsize_update, storage_exports

ZONE = "lab.example"

CATALOG = {
    "debian/app": {
        "storage": [
            {"app": "web", "dataset": "db", "recordsize": "32K"},
            {"app": "web", "dataset": "data"},
        ]
    },
    "debian/plain": {"storage": []},
    "debian/old": {},
}


def test_exports_per_dataset_with_hosts():
    exports = storage_exports(CATALOG, {"vm1": "debian/app", "vm0": "debian/app"}, ZONE)

    assert exports == [
        {"app": "web", "dataset": "data", "hosts": ["vm0.lab.example", "vm1.lab.example"]},
        {"app": "web", "dataset": "db", "recordsize": "32K", "hosts": ["vm0.lab.example", "vm1.lab.example"]},
    ]


def test_images_without_storage_give_nothing():
    assert storage_exports(CATALOG, {"a": "debian/plain", "b": "debian/old"}, ZONE) == []


def test_images_sharing_a_dataset_share_the_export():
    catalog = {**CATALOG, "debian/other": {"storage": [{"app": "web", "dataset": "data"}]}}

    exports = storage_exports(catalog, {"vm1": "debian/app", "vm2": "debian/other"}, ZONE)

    data = next(e for e in exports if e["dataset"] == "data")
    assert data["hosts"] == ["vm1.lab.example", "vm2.lab.example"]


def test_conflicting_recordsize_fails():
    catalog = {**CATALOG, "debian/other": {"storage": [{"app": "web", "dataset": "db", "recordsize": "1M"}]}}

    with pytest.raises(AnsibleFilterError, match="recordsize"):
        storage_exports(catalog, {"vm1": "debian/app", "vm2": "debian/other"}, ZONE)


def test_unknown_image_fails():
    with pytest.raises(AnsibleFilterError, match="not in the catalog"):
        storage_exports(CATALOG, {"vm1": "debian/missing"}, ZONE)


@pytest.mark.parametrize("name", ["..", ".", "a/b", "", ".hidden"])
def test_unsafe_names_fail(name):
    catalog = {"debian/bad": {"storage": [{"app": name, "dataset": "data"}]}}

    with pytest.raises(AnsibleFilterError, match="invalid storage name"):
        storage_exports(catalog, {"vm1": "debian/bad"}, ZONE)


def test_empty_zone_fails():
    with pytest.raises(AnsibleFilterError, match="zone"):
        storage_exports(CATALOG, {"vm1": "debian/app"}, "")


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
