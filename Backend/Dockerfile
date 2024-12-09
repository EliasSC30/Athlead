# Use the Rust official image for the build stage
FROM rust:latest AS build

# Set the working directory inside the container
WORKDIR /athlead

# Copy over only the Cargo.toml and Cargo.lock files first (to cache dependencies)
COPY Cargo.toml Cargo.lock ./

# Create a dummy main.rs file to ensure the build caches dependencies properly
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Pre-build the dependencies
RUN cargo build --release && rm -rf target/release && rm -rf src

# Copy the actual source code
COPY ./src ./src

# Build the final release binary
RUN cargo build --release

# Use a smaller base image for the final stage
FROM debian:buster-slim

# Set the working directory
WORKDIR /app

# Copy the compiled binary from the build stage
COPY --from=build /athlead/target/release/athlead .

# Set the startup command to run your binary
CMD ["./athlead"]
