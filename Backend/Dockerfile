# Use the official Rust slim image for a smaller base image
FROM rust:slim AS builder

# Set the working directory
WORKDIR /app

# Install necessary build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config libssl-dev build-essential && \
    rm -rf /var/lib/apt/lists/*

# Cache dependencies to speed up subsequent builds
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# Copy the application source code
COPY . ./

# Build the release binary
RUN cargo build --release

# Use a minimal runtime image
FROM debian:bookworm-slim AS runtime

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the release binary from the builder stage
COPY --from=builder /app/target/release/Athlead .

# Expose the application port
EXPOSE 8000

# Run the binary
CMD ["./Athlead"]
