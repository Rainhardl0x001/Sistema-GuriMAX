FROM golang:1.27.0-bookworm AS builder

WORKDIR /src

COPY go.mod ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
	-trimpath \
	-ldflags="-s -w" \
	-o /out/api ./cmd/api

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN useradd --system --no-create-home --shell /usr/sbin/nologin appuser

COPY --from=builder /out/api /app/api

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
	CMD ["/app/api", "healthcheck"]

ENTRYPOINT ["/app/api"]
