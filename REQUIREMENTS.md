# Requirement mapping

The application uses the approved Java/JUnit/Flyway equivalent of the Python reference. Both Docker deployment methods (individual `docker run` commands and Docker Compose) are verified. The [walkthrough video](demo/browser-walkthrough.mp4) and [browser screenshots](screenshots/browser/) show the application, Prometheus, Grafana and Argo CD. Full rubric completion still requires the AWS run below; there are no AWS Console images because no cloud cluster was created.

| Module | Implementation and verification | Remaining item |
|---|---|---|
| M1 Application | React query catalog; Spring health, GET/POST/PUT/DELETE, PostgreSQL/Flyway; real Compose and Ingress smoke checks; Playwright/CDP CRUD and mobile checks | None; browser screenshots and an MP4 walkthrough are included |
| M2 Testing | 15 Java tests, including 12 isolated API cases; JUnit XML and actual Gradle output; CI test gate precedes image builds | None for the approved language mapping |
| M3 Git | Public standalone repository; more than twenty meaningful commits carried over from the course repository plus the work done here; ignored credentials, build files and state | None |
| M4 Docker | Multi-stage frontend and backend builds; UID 101/65532; direct `docker run` and full Compose deployments; actual health/readiness, browser CRUD, persistence and API tests | None; browser screenshots of the running stack are included |
| M5 CI/CD | Push, pull request and manual triggers; tests/frontend build; three SHA-tagged images; GHCR push/pull; temporary kind Helm deployment and cleanup | None; the latest green run is linked from the README |
| M6 DevSecOps | SAST, source dependencies, Git-history secret scan and all three image gates; zero HIGH/CRITICAL after fixes; first failing image report retained | None for implemented scan gates |
| M7 Terraform/AWS | Valid Terraform; init and nonempty 21-resource plan; VPC/two public subnets/EKS/node group/EBS definitions | AWS permissions/account compatibility, real apply/verification/destroy, console evidence |
| M8 Kubernetes/Helm | Namespace/bootstrap, external Secrets, two replicas per application service, ClusterIP/Ingress, health probes, HPA 2 → 3 → 2, persistent PostgreSQL/Kafka | Real EKS execution; local Ingress browser screenshots are included |
| M9 Observability | Per-replica Prometheus targets UP; Grafana dashboard with real request-rate frames; logs and alert rules | None; Prometheus Targets and Grafana dashboard screenshots are included |
| M10 Presentation | Architecture, instructions, CVE explanation, failure analysis, terminal commit-to-deployment recording, browser walkthrough video, 14-slide deck (PPTX and PDF) and presentation guide | AWS demonstration |

The local Kubernetes run and CI kind run do not substitute for the explicitly required EKS deployment. Terraform plans and failed AWS permission checks do not count as successful infrastructure creation.
