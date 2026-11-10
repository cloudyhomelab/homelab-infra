# cloudyhome-truenas-app-storage

TrueNAS datasets and NFS shares for the storage that images declare, with each share allowing exactly the clients whose image uses it.

## Inputs

- `root`: existing dataset holding the app datasets, e.g. `tank/app_data`. Not created here, as several callers share it.
- `images`: image key => `{type, storage}`, `storage` a list of `{app, dataset, recordsize?}`.
- `clients`: client key => `{image, address}`; `address` is a bare IPv4 address, null when the client has none.

## Layout and access

- One dataset per `app` and `dataset` pair at `<root>/<app>/<dataset>`, plus `<root>/<app>`. Datasets belong to images, not clients: images naming the same pair share the dataset and must agree on its `recordsize`.
- One NFS share per dataset, commented with the image types using it, allowing only the addresses of the clients whose image names it (no networks), with root mapped to `root`.
- Clients are allowed by address, never by name: the NFS server resolves names only when it loads the exports, so a DNS record added later stays unseen until mountd restarts. A client without an address fails the plan.
- The share owns its whole host list: a client is added or removed by the next apply after it joins or leaves `clients`.

## Never removes

Every dataset has `prevent_destroy`, so neither dropping a pair nor destroying the caller deletes data; deleting a dataset is a manual step after removing it from state. Shares have no such guard, as they hold no data.

A dataset path has one owner. Two root modules naming the same pair would fight over the dataset and its share; neither can detect the other.

## Tests

```sh
tofu init && tofu test
```

Plan-only runs against a mocked provider.
