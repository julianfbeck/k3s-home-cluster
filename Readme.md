- Master: Hostname: Main, Adress: 192.168.178.170 Memory: 2gb, Mac E4:5F:01:1E:B8:C8
- Node 2: Hostname: worker2 Adress: 192.168.178.27  Memory: 4gb
- Node 1: Hostname: node1 Adress: 192.168.178.94 Memory 4gb

- Main New: 192.168.178.74
  Mac: E4:5F:01:98:B1:8D


## k3s version

All three nodes run **k3s v1.35.4+k3s1** on **cgroup v2**.

k3s 1.35 dropped support for cgroup v1, so the Pi boot cmdline must include
`systemd.unified_cgroup_hierarchy=1` on every node. The original cmdline is
backed up to `/boot/cmdline.txt.bak.before-cgroupv2`.

## Upgrading

Use the system-upgrade-controller. Edit the `version:` field in
`upgrade/system-upgrade.yml` (in `spec.version`, not `spec.upgrade.version`)
and `kubectl apply -f`. The controller drains nodes one at a time, replaces
the k3s binary, and uncordons.

The ServiceAccount and RBAC for the controller live in the `system-upgrade`
namespace; Plans must live there too.

## NFS

The `nfs-csi` storage class is backed by TrueNAS at `192.168.178.77:/mnt/Ohara/k8s`
via `csi-driver-nfs` (manifests under `kube-system/csi-driver-nfs/`). NFSv3 because
NFSv4 isn't enabled on TrueNAS; flip both ends (Services → NFS → Enabled Protocols,
and `nfsvers=` in the storage class) to move to v4.1.
