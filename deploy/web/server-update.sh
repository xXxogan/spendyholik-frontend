#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [[ ! ${SSH_ORIGINAL_COMMAND:-} =~ ^deploy\ ([0-9a-f]{40})$ ]]; then
  echo 'Expected deploy followed by a full commit SHA.' >&2
  exit 2
fi
revision=${BASH_REMATCH[1]}
image="spendyholik-web:$revision"
namespace=spendyholik
deployment=deployment/spendyholik-web
revision_url=https://spendyholik.duckdns.org/deploy-revision.txt
policy_url=https://spendyholik.duckdns.org/privacy-policy.md

exec 9>/run/lock/spendyholik-web-deploy.lock
flock -w 60 9

kube() {
  k3s kubectl -n "$namespace" "$@"
}

previous=$(kube get "$deployment" -o 'jsonpath={.spec.template.spec.containers[?(@.name=="web")].image}')
policy=$(kube get configmap spendyholik-web-policy -o 'jsonpath={.data.privacy_policy_ru\.md}')
[[ -n "$previous" && -n "$policy" ]]

timeout 180 gzip -dc | k3s ctr images import --platform linux/amd64 -
k3s ctr images check -q "name==docker.io/library/$image" | grep -Fxq "docker.io/library/$image"

kube set image "$deployment" "web=$image"
if kube rollout status "$deployment" --timeout=90s &&
   actual=$(curl -fsS --retry 3 --retry-all-errors --max-time 8 "$revision_url?rev=$revision") &&
   [[ "$actual" == "$revision" ]] &&
   published_policy=$(curl -fsS --retry 3 --retry-all-errors --max-time 8 "$policy_url") &&
   [[ "$published_policy" == "$policy" ]]; then
  printf 'Deployed %s\n' "$revision"
  exit 0
fi

printf 'Release %s did not pass checks. Restoring %s\n' "$revision" "$previous" >&2
kube set image "$deployment" "web=$previous"
kube rollout status "$deployment" --timeout=90s
exit 1
