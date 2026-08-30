#!/usr/bin/env bash
set -euo pipefail

build_dir="${1:?build directory is required}"
sanitizer="${2:?sanitizer name is required}"
case "$sanitizer" in
  asan)
    export ASAN_OPTIONS="detect_leaks=1:halt_on_error=1:allow_addr2line=1:external_symbolizer_path=/usr/bin/addr2line"
    export UBSAN_OPTIONS="halt_on_error=1"
    ;;
  tsan)
    export TSAN_OPTIONS="halt_on_error=1:ignore_interceptors_accesses=1:suppressions=/opt/userver/cmake/tsan.suppressions.txt:allow_addr2line=1:external_symbolizer_path=/usr/bin/addr2line"
    ;;
  *)
    echo "unsupported sanitizer: $sanitizer" >&2
    exit 2
    ;;
esac

service_dirs=(
  "."

)
service_targets=(
  "example_inventory_service"
)
service_names=(
  "inventoryservice"
)
http_ports=(
  "9092"
)
grpc_ports=(
  "9202"
)
secdist_values=(
  ''
)

if [[ "${#service_dirs[@]}" -eq 0 ]]; then
  echo "sanitizer runtime gate has no generated services" >&2
  exit 2
fi

config_dir="${build_dir%/}/sanitizer-config"
mkdir -p "$config_dir"
for index in "${!service_dirs[@]}"; do
  service_dir="${service_dirs[$index]}"
  service_name="${service_names[$index]}"
  cp "$service_dir/config/config_vars.integration.yaml" \
    "$config_dir/$service_name.yaml"
done

# Sanitized processes share one container. Replace generated Compose service
# DNS with loopback only in disposable copies of their runtime variables.
for config in "$config_dir"/*.yaml; do
  for index in "${!service_dirs[@]}"; do
    service="${service_names[$index]}"
    grpc_port="${grpc_ports[$index]}"
    sed -i -e "s|dns:///$service:$grpc_port|dns:///127.0.0.1:$grpc_port|g" "$config"
  done
done

pids=()
stop_services() {
  local pid
  for pid in "${pids[@]}"; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
  pids=()
}
terminate_services() {
  stop_services
  exit 0
}
trap stop_services EXIT
trap terminate_services INT TERM

for index in "${!service_dirs[@]}"; do
  service_dir="${service_dirs[$index]}"
  service_name="${service_names[$index]}"
  target="${service_targets[$index]}"
  secdist="${secdist_values[$index]}"
  (
    cd "$service_dir"
    environment=(SERVICELIB_NOOP_METRICS=1)
    if [[ -n "$secdist" ]]; then
      environment+=("SECDIST_CONFIG=$secdist")
    fi
    exec env "${environment[@]}" \
      "${build_dir%/}/$target" \
        --config static_config.yaml \
        --config_vars "$config_dir/$service_name.yaml"
  ) &
  pids+=("$!")
done

http_ports_csv="$(IFS=,; echo "${http_ports[*]}")"
ready=0
ready_deadline=$((SECONDS + 120))
while (( SECONDS < ready_deadline )); do
  if HTTP_PORTS="$http_ports_csv" python3 - <<'PY' >/dev/null 2>&1
import json
import os
import urllib.request

for port in os.environ["HTTP_PORTS"].split(","):
    with urllib.request.urlopen(
        f"http://127.0.0.1:{port}/status/data", timeout=2
    ) as response:
        graph = json.load(response)
        assert set(("nodes", "edges")) <= graph.keys()
        assert graph["nodes"]
PY
  then
    ready=1
    break
  fi
  for pid in "${pids[@]}"; do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "sanitized generated service exited before readiness" >&2
      exit 1
    fi
  done
  sleep 0.1
done
if [[ "$ready" -ne 1 ]]; then
  echo "sanitized generated services did not become ready" >&2
  exit 1
fi

HTTP_PORTS="$http_ports_csv" python3 - <<'PY'
import json
import os
import urllib.request

for port in os.environ["HTTP_PORTS"].split(","):
    for path in ("/health/startup", "/health/ready", "/health/live", "/status/data"):
        with urllib.request.urlopen(
            f"http://127.0.0.1:{port}{path}", timeout=5
        ) as response:
            assert response.status == 200
            if path == "/status/data":
                graph = json.load(response)
                assert isinstance(graph["nodes"], list)
                assert isinstance(graph["edges"], list)
                assert graph["nodes"]
print("generated C++ sanitizer runtime gate: PASS")
PY

if [[ "${SANITIZER_HOLD:-0}" == "1" ]]; then
  wait -n "${pids[@]}"
  exit $?
fi

status=0
for pid in "${pids[@]}"; do
  kill -TERM "$pid" 2>/dev/null || true
done
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    status=1
  fi
done
pids=()
exit "$status"