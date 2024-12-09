# 1. Use the official Rust image as the builder stage
FROM rust:latest AS builder

# Set environment variables for Rust build optimizations
ENV CARGO_HOME=/usr/local/cargo \
    RUSTFLAGS="-C target-cpu=native"

# 2. Create a directory for the project
WORKDIR /app

# 3. Copy and build dependencies separately to leverage caching
COPY Cargo.toml Cargo.lock ./
RUN cargo fetch --locked
RUN cargo build --release && rm -rf target/release/build

# 4. Copy source code and rebuild
COPY ./src ./src
RUN cargo build --release --locked

# 5. Use a minimal image for the runtime
FROM debian:buster-slim AS runtime

# Set environment variables
ENV CARGO_HOME=/usr/local/cargo

# Install necessary dependencies for Rust binaries
RUN apt-get update && apt-get install -y libssl-dev ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the builder
COPY --from=builder /app/target/release/athlead /usr/local/bin/athlead

# Set the binary as the default command
CMD ["athlead"]
