# Docker Course Guestbook

The single running example for the **4-day Docker course**. A tiny
**Java 21 + Spring Boot** guestbook that stores messages in **PostgreSQL** — you
carry this one app from a bare source tree on Day 1 to a signed, multi-arch image
shipped by CI on Day 4.

The point isn't the app (it's one file). The point is how it ships.

---

## Start anywhere: the checkpoint tags

The repo is one commit per day. `main` is the bare skeleton (no Docker files yet);
each tag is the finished state of a day, which is also the *starting* state of the
next. Check out the tag for wherever you are — you never have to have done the
previous day.

```bash
git clone https://github.com/githubmo/docker-course-guestbook
cd docker-course-guestbook

git checkout day2-start      # source only — you write the Dockerfile
git checkout day2-solution   # multi-stage Dockerfile done  (= day3-start)
git checkout day3-solution   # full compose stack done      (= day4-start)
git checkout final           # CI + patched Tomcat pin
```

| Tag | State | You get |
|-----|-------|---------|
| `main` / `day2-start` | Skeleton | `pom.xml`, `src/`, no Docker files |
| `day2-solution` / `day3-start` | Built | + multi-stage `Dockerfile`, `.dockerignore` |
| `day3-solution` / `day4-start` | Stacked | + `docker-compose.yml`, `.env.example` |
| `final` | Shipped | + `.github/workflows/ci.yml`, patched Tomcat pin |

---

## What you do each day

| Day | Exercise | Checkpoint |
|-----|----------|------------|
| 1 | Run the data tier: bring up just Postgres, `psql` in, see the empty `guestbook` table | `main` |
| 2 | Containerise the service: naive Dockerfile → real multi-stage build + `.dockerignore` + `--mount=type=cache` | `day2-start` → `day2-solution` |
| 3 | Full stack in Compose: app + Postgres + a lightweight Mongo tier + Adminer, wired by service name | `day3-start` → `day3-solution` |
| 4 | Ship it: Docker Scout finds 4 critical Tomcat CVEs → pin the patched version → SBOM, cosign sign, multi-arch, CI push | `day4-start` → `final` |

---

## Run it locally (from `day3-solution` or later)

```bash
cp .env.example .env          # Compose reads secrets from here (.env is git-ignored)
docker compose up --build
```

| URL | What it is |
|-----|------------|
| http://localhost:8080 | The app — sign the guestbook |
| http://localhost:8081 | Adminer — DB admin UI (System `PostgreSQL`, Server `db`, Database `guestbook`, user/pass from your `.env`) |

Add a message, then `docker compose restart app` — it survives, because the data
lives in the `pgdata` named volume, not the container. `docker compose ps` shows
the Mongo tier running alongside; the app doesn't depend on it — it's there so you
can watch a second data service and `mongosh` into it.

Tear down with `docker compose down` (add `-v` to also wipe the volumes).

---

## The finished image

Day 1 can run the finished app before building it:

```bash
docker pull mzawi/guestbook:final
```

(Published to Docker Hub by the `final` CI pipeline — see `.github/workflows/ci.yml`.)
