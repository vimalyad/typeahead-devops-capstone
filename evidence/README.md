# Evidence provenance

All results come from actual executions on 7 October 2026. Local JSON summaries are written only after their HTTP/Kubernetes assertions pass. The CI directory contains downloaded GitHub Actions artifacts and run metadata. Raw reports retain their original contents. `local/record-index.json` maps local source filenames to their copied submission filenames.

`local/dns-before-extract.txt` and `local/dns-after-extract.txt` select original log lines containing `consumer session failed`, `No resolvable bootstrap urls`, or `flushed 1 distinct queries`. They are excerpts, not a reconstructed application log. Full local logs remain in the workspace. The first failed container scan is in `security-failure/`; it demonstrates the enforced image gate and is not a successful release report.

Screenshots are captures of the xterm surface connected to a real Bash PTY, using Playwright with Chromium's CDP connection. They contain no browser chrome or unrelated desktop content. When a screenshot displays a saved run, its `cat`, `tail`, or `jq` command is visible. Recorded terminal output is not passed off as a fresh cloud apply.

`commit-to-deployment.cast` records real PTY output chunks with elapsed timestamps in asciicast v2 format. `commit-to-deployment.txt` preserves the same terminal stream for text inspection. The recording includes real waiting time for CI and GitOps reconciliation. No fabricated command output or simulated cloud resources are included.

AWS capstone evidence currently consists of initialization, validation/planning and permission checks. The [latest checks](local/aws-access-latest.json) still returned access denials on 7 October 2026. There is no successful EKS apply or destroy record yet. Terminal API evidence for Grafana and Prometheus is distinct from the browser screenshots requested by the rubric.

## Verified release

The complete [recorded pipeline run](https://github.com/vimalyad/devops-heros/actions/runs/37588149332) passed tests, source security, image security/publication, and the temporary Kubernetes deployment. [Run metadata](ci/run.json), [JUnit results](ci/tests), [source scans](ci/source-security), [image scans and digests](ci/images), and [deployment/cleanup output](ci/deployment) are retained here after the hosted artifacts expire.

[Release summary](release-summary.json) identifies source commit `0f8f27c95cae983b8274d649db2435200450c48a` and promotion commit `044fcd992a881f610cf778e95419e1972590dc45`. [Argo status](local/argocd-final.json) records Healthy/Synced at the promotion. [Deployed image verification](local/deployed-image-verification.json) compares all six ready application replicas with the scanned and published images. Later documentation commits do not change that tested application source.

## Terminal captures

| Capture | Evidence |
|---|---|
| [01 Tests](../screenshots/01-tests.png) | Actual Java test output and frontend build records |
| [02 Compose](../screenshots/02-compose.png) | Full-stack smoke and database persistence |
| [03 Browser checks](../screenshots/03-browser-checks.png) | Playwright/CDP CRUD and mobile assertions displayed in the terminal |
| [04 Kubernetes](../screenshots/04-kubernetes.png) | Helm releases, deployments, StatefulSets and ready pods |
| [05 Network/storage](../screenshots/05-network-storage.png) | Services, Ingress, HPA and bound PVCs |
| [06 Health/metrics](../screenshots/06-health-metrics.png) | Live Spring health and Prometheus metrics |
| [07 Monitoring](../screenshots/07-monitoring.png) | Live UP targets and recorded Grafana query frames |
| [08 Scaling/persistence](../screenshots/08-scaling-storage.png) | Actual HTTP load, HPA scaling and database pod replacement |
| [09 Recovery](../screenshots/09-fault-recovery.png) | Kafka DNS recovery, Service selector repair and Argo drift correction |
| [10 CI/security](../screenshots/10-pipeline-security.png) | Final green pipeline and all three clean image reports |
| [11 GitOps](../screenshots/11-gitops-history.png) | Exact Argo revision, live application version and meaningful commit history |
| [12 Recorded release](../screenshots/12-recorded-release-demo.png) | Final screen of the actual timed commit-to-deployment recording |
| [13 Terraform/access](../screenshots/13-terraform-and-access.png) | Validation/plan and explicit AWS access failures |
| [14 Cleanup](../screenshots/14-cleanup.png) | Actual local teardown, stopped cluster and CI kind deletion |
| [15 Direct containers](../screenshots/15-direct-containers.png) | Live `docker run` deployment, both backends' health/readiness and full-stack smoke |
| [16 Direct-run cleanup](../screenshots/16-direct-cleanup.png) | Playwright/CDP browser assertions and removal of all direct-run resources |

The corresponding `NN-*-terminal.txt` files preserve captured terminal streams, including control sequences. [The asciicast recording](commit-to-deployment.cast) preserves elapsed time; [its transcript](commit-to-deployment.txt) is also available as text.

## Cleanup

[Local cleanup assertions](local/cleanup.json) passed after the application, monitoring, Argo CD and ingress resources were removed. Only the four default Kubernetes namespaces remained, no assignment PersistentVolumes remained, and the Compose project had no containers, networks or volumes. The dedicated Minikube cluster was then stopped. The nine unrelated running containers kept their original IDs.

[Cleanup command output](local/cleanup-command-extract.txt) preserves the actual teardown output, omitting the two global `docker container ls --format json` command blocks because they expose unrelated applications' metadata. The full raw log remains in the private workspace. No other lines were rewritten. [CI cleanup](ci/deployment/cleanup.txt) independently confirms deletion of its temporary kind cluster. No capstone AWS apply was attempted.

The later direct-container run is recorded separately in [direct verification](local/direct-verification.json), [browser checks](local/direct-browser-check.json), [startup output](local/direct-startup.txt), [cleanup output](local/direct-cleanup.txt), and [cleanup assertions](local/direct-cleanup.json). Docker's containerd image store reports manifest digests; Trivy's `ImageID` identifies the image config. This record compares published repository digests and scanned filesystem-layer digests explicitly instead of treating the two kinds of digest as interchangeable.
