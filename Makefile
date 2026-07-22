# kubectl access to the k3s cluster via the Mac mini (Tailscale) as jump host.
#
# The cluster API (https://192.168.178.170:6443) is only reachable from the
# home LAN. The mini is on that LAN and reachable via Tailscale, so we forward
# a local port through it. The kubeconfig context `default-via-mini-tunnel`
# points at https://127.0.0.1:16443.
#
# Usage:
#   make tunnel          # start the SSH tunnel (idempotent)
#   kubectl --context default-via-mini-tunnel get nodes
#   make tunnel-stop     # tear it down
#   make status          # tunnel + cluster health overview

MINI        := mini
MASTER_IP   := 192.168.178.170
LOCAL_PORT  := 16443
CONTEXT     := default-via-mini-tunnel
FORWARD     := $(LOCAL_PORT):$(MASTER_IP):6443

.PHONY: tunnel tunnel-stop tunnel-status status kubeconfig-use

tunnel:
	@if pgrep -f "ssh.*-L $(FORWARD)" >/dev/null; then \
		echo "Tunnel already running (localhost:$(LOCAL_PORT) -> $(MASTER_IP):6443 via $(MINI))"; \
	else \
		ssh -f -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 \
			-L $(FORWARD) $(MINI) && \
		echo "Tunnel started: localhost:$(LOCAL_PORT) -> $(MASTER_IP):6443 via $(MINI)"; \
	fi
	@echo "Use: kubectl --context $(CONTEXT) get nodes   (or: make kubeconfig-use)"

tunnel-stop:
	@pkill -f "ssh.*-L $(FORWARD)" && echo "Tunnel stopped." || echo "No tunnel running."

tunnel-status:
	@if pgrep -f "ssh.*-L $(FORWARD)" >/dev/null; then \
		echo "Tunnel: RUNNING (localhost:$(LOCAL_PORT) -> $(MASTER_IP):6443 via $(MINI))"; \
	else \
		echo "Tunnel: NOT RUNNING (start with: make tunnel)"; \
	fi

# Switch the current kubectl context to the tunnel context.
kubeconfig-use:
	kubectl config use-context $(CONTEXT)

# Overview: tunnel state, master reachability from the mini, API health.
status: tunnel-status
	@echo "--- master reachability (checked from $(MINI)) ---"
	@ssh -o ConnectTimeout=5 -o BatchMode=yes $(MINI) \
		"nc -z -G 3 $(MASTER_IP) 6443 && echo 'master $(MASTER_IP):6443 reachable' || echo 'master $(MASTER_IP):6443 UNREACHABLE'"
	@echo "--- API via tunnel ---"
	@kubectl --context $(CONTEXT) get nodes --request-timeout=5s 2>/dev/null || \
		echo "API not responding (is the tunnel up and the master online?)"
