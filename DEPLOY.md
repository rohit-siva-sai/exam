# Docker Deploy (JSP + Tomcat)

## Build locally
`docker build -t exam-grid-jsp .`

## Run locally
`docker run --rm -p 8080:8080 exam-grid-jsp`

Open: `http://localhost:8080/`

## Deploy to Render
1. Push this project to GitHub.
2. In Render, create a new **Web Service** from the repo.
3. Render will detect `render.yaml`/`Dockerfile` and build automatically.

## Deploy to Railway
1. Push this project to GitHub.
2. In Railway, create a new project from your repo.
3. Railway auto-builds using `Dockerfile`.
4. Set port to `8080` only if Railway asks (usually auto-detected).

## Notes
- Data is in-memory right now; restarts will reset users/tests/results.
- For production, migrate to MySQL/PostgreSQL.
