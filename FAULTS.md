# Failure diagnosis and recovery

These exercises ran against the isolated local Compose/Kubernetes stacks. AWS was not used.

| Fault | Observation | Diagnosis and correction | Verification |
|---|---|---|---|
| Kafka bootstrap hostname absent at startup | `No resolvable bootstrap urls` | The original worker exited its background thread permanently. It now creates a new consumer session after a bounded delay; uncommitted offsets replay. | After adding the broker DNS alias, the same container consumed an event, updated PostgreSQL and refreshed suggestions. No container restart was used to recover. |
| Ingestion Service selector changed to a nonexistent pod label | Ingress returned 503; EndpointSlice had no endpoints | Compared the Service selector with pod labels and restored `app=ingestion-service`. | The same route returned HTTP 200. |
| PostgreSQL pod deleted | StatefulSet created a replacement pod | Confirmed the new pod mounted the existing PVC. | A row created before deletion retained its value of 17 and was read through the API, then removed. |
| Frontend Service selector drifted from Git | Live selector became `frontend-drift` | Argo CD detected the managed-field change and applied the Git definition. | Selector returned to `frontend` in 2.09 seconds without an imperative repair. |

The first Kubernetes launch also exposed a headless-service bootstrap dependency: Kafka could not resolve its own controller hostname until it was Ready, while readiness required that controller connection. `publishNotReadyAddresses: true` breaks that cycle. The initial failed smoke test prevented this deployment from being reported as complete.

An exploratory change to Service `targetPort: 9999` did not produce an observed Ingress failure within a 15-second window. It was restored and is not used as outage evidence. The selector exercise above is the verified Service failure.

Evidence lives in [evidence/local](evidence/local): `dns-recovery.json`, the selected real DNS log lines, `service-recovery.json`, the empty EndpointSlice response, `kubernetes-persistence.json`, and `gitops-drift-repair.json`. The HTTP load was actual traffic: 120,415 successful requests from 16 clients over 80 seconds, with zero client failures. HPA samples show the suggestion service scaling 2 → 3 → 2.

This small run demonstrates functionality and autoscaling under its recorded conditions. It is not a production throughput benchmark. Kafka and PostgreSQL intentionally have one instance each for the temporary lab, and event processing is at least once, so a failure between a database commit and an offset commit can repeat a count.
