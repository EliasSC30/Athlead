# Stage 1: Build stage
FROM rust:latest AS builder

# Set the working directory inside the container
WORKDIR /usr/src/athlead

# Copy only the Cargo files to leverage caching
COPY Cargo.toml Cargo.lock ./

# Pre-fetch dependencies (caching layer for dependencies)
RUN cargo fetch

# Copy the source code
COPY ./ ./

# Build the program in release mode
RUN cargo build --release

# Stage 2: Runtime stage
FROM debian:buster-slim

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /usr/src/athlead/target/release/athlead /app/athlead

# Expose any required ports (e.g., 8080 for your application)
EXPOSE 8000

# Run the binary
CMD ["./athlead"]
