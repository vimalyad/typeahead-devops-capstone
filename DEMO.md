# Presentation walkthrough

Start with the [architecture and run instructions](README.md), then explain the query catalog in one minute: CRUD stores catalog entries; search events flow through Kafka into PostgreSQL; the suggestion service rebuilds a trie and caches results in Redis.

The [terminal recording](evidence/commit-to-deployment.cast) uses the asciicast v2 format. It records actual output and timing from a spawned Bash PTY, viewed through Playwright/CDP. Replay it with an asciicast-compatible player, for example:

```bash
asciinema play evidence/commit-to-deployment.cast
```

The recording lasts about 10 minutes 37 seconds and follows [run 37588149332](https://github.com/vimalyad/devops-heros/actions/runs/37588149332), source commit `0f8f27c`, and promotion commit `044fcd9`.

The recorded release changes the cache inspector's outdated fixed Redis-node count and its layout, and labels the search field for the query catalog. It shows the real diff, frontend build, commit and push, GitHub Actions progression, GHCR pulls, local image loading, a separate promotion commit, Argo CD reaching that exact revision, the live `/info` version, and the Ingress smoke test. The visible command runs a shell script; the recording is not a claim that each command was typed manually.

Use the recording and saved records to cover these points:

1. Show one create/update/delete operation and distinguish mocked controller tests from the real integration smoke check.
2. Explain the two Docker build stages and runtime UIDs. Show the SHA tags and why the pipeline rejects a HIGH/CRITICAL finding before publishing.
3. Explain the failed Debian image scan and the runtime/dependency corrections in [SECURITY.md](SECURITY.md).
4. Show two frontend and two replicas of each backend, PVCs, health probes and the HPA 2 → 3 → 2 record.
5. Show Prometheus UP targets and Grafana's positive request-rate frames. Explain which requests produced them.
6. Explain the Kafka startup failure and automatic consumer recovery, Service selector failure, database persistence and Argo drift repair from [FAULTS.md](FAULTS.md).
7. Show the promotion commit, Argo's matching revision, and the application's reported version.
8. Finish with the actual AWS plan and state the outstanding cloud permission/apply/destroy work. Add real AWS evidence before presenting that module as complete.

Browser, AWS Console, Prometheus Targets and Grafana screenshots are explicitly requested by the rubric. They are omitted under the terminal-only instruction; the supplied browser assertions and API responses are not described as browser screenshots.
