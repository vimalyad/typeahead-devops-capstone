# Requirement mapping

The application uses the approved Java/JUnit/Flyway equivalent of the Python reference. Both Docker deployment methods demonstrated in Aryen's reference are verified. Full rubric completion still requires the AWS run below. Terminal-only screenshots follow the requested format; they do not fulfill the rubric's separate requests for browser/console/dashboard images.

| Module | Implementation and verification | Remaining item |
|---|---|---|
| M1 Application | React query catalog; Spring health, GET/POST/PUT/DELETE, PostgreSQL/Flyway; real Compose and Ingress smoke checks; Playwright/CDP CRUD and mobile checks | Rubric requests a browser screenshot/recording; requested evidence format is terminal-only |
| M2 Testing | 15 Java tests, including 12 isolated API cases; JUnit XML and actual Gradle output; CI test gate precedes image builds | None for the approved language mapping |
| M3 Git | Public fork and central PR; more than ten meaningful commits; ignored credentials, build files and state | PR remains unmerged as requested |
| M4 Docker | Multi-stage frontend and backend builds; UID 101/65532; direct `docker run` and full Compose deployments; actual health/readiness, browser CRUD, persistence and API tests | Browser images omitted under the terminal-only instruction |
| M5 CI/CD | Main/assignment branch triggers; tests/frontend build; three SHA-tagged images; GHCR push/pull; temporary kind Helm deployment and cleanup | Recorded final run is linked in the evidence index |
| M6 DevSecOps | SAST, source dependencies, Git-history secret scan and all three image gates; zero HIGH/CRITICAL after fixes; first failing image report retained | None for implemented scan gates |
| M7 Terraform/AWS | Valid Terraform; init and nonempty 21-resource plan; VPC/two public subnets/EKS/node group/EBS definitions | AWS permissions/account compatibility, real apply/verification/destroy, console evidence |
| M8 Kubernetes/Helm | Namespace/bootstrap, external Secrets, two replicas per application service, ClusterIP/Ingress, health probes, HPA 2 → 3 → 2, persistent PostgreSQL/Kafka | Real EKS execution; browser images omitted under the terminal-only instruction |
| M9 Observability | Per-replica Prometheus targets UP; Grafana dashboard with real request-rate frames; logs and alert rules | Rubric requests dashboard/Targets screenshots; current captures show real API evidence in terminals |
| M10 Presentation | Architecture, instructions, CVE explanation, failure analysis, terminal commit-to-deployment recording and presentation guide | AWS demonstration and final presentation/submission |

The local Kubernetes run and CI kind run do not substitute for the explicitly required EKS deployment. Terraform plans and failed AWS permission checks do not count as successful infrastructure creation.
