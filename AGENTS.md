# AGENTS.md

## Kubernetes access in this repo

This repo uses a k3s cluster whose API server is on the home LAN at:

- `https://192.168.178.170:6443`

Direct access only works when the machine running `kubectl` can reach that LAN.

## Tailscale and Mini tunnel

There is a Tailscale-connected Mac Mini at:

- `julianbeck@100.104.222.79`

When direct LAN access is unavailable, use the Mini as the network bridge over SSH.

Current working tunnel command:

```bash
autossh -M 0 -f -N \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -o ExitOnForwardFailure=yes \
  -L 16443:192.168.178.170:6443 \
  julianbeck@100.104.222.79
```

This exposes the cluster API locally at:

- `https://127.0.0.1:16443`

## kubeconfig contexts

`~/.kube/config` is expected to contain these contexts:

- `default`: direct access to `https://192.168.178.170:6443`
- `default-via-mini-tunnel`: access through `https://127.0.0.1:16443`

Use the tunnel-backed context when working remotely:

```bash
kubectl config use-context default-via-mini-tunnel
```

Use the direct context when on the local network:

```bash
kubectl config use-context default
```

## Verification

Before making cluster changes through the tunnel, verify both the SSH forward and Kubernetes access:

```bash
lsof -nP -iTCP:16443 -sTCP:LISTEN
kubectl --context default-via-mini-tunnel get ns
```

## Important notes

- Do not silently repoint the `default` context to the tunnel. Keep direct and tunneled access as separate contexts.
- If `kubectl --context default-via-mini-tunnel` fails, first restart the `autossh` tunnel.
- The Mini has been configured to advertise a Tailscale exit node, but this setup currently relies on the SSH tunnel, not on Tailscale exit-node routing.
