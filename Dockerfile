# ====================== BUILD STAGE ======================
FROM golang:1.24.8-bookworm AS builder

WORKDIR /usr/src/app

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

RUN go build -v -o /run-app ./cmd/server

# ====================== RUNTIME STAGE ======================
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates tzdata && rm -rf /var/lib/apt/lists/*

RUN groupadd -r appgroup && useradd -r -g appgroup -s /sbin/nologin appuser

WORKDIR /app

COPY --from=builder /run-app /app/run-app
COPY --from=builder /usr/src/app/web /app/web
COPY --from=builder /usr/src/app/internal/templates /app/internal/templates

RUN mkdir -p /app/web/static /app/pb_data && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["sh", "-c", "wget -qO- http://localhost:3000/ || exit 1"]

CMD ["/app/run-app", "serve"]
