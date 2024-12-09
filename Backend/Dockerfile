# Use an official Rust image as the base for building
FROM rust:latest AS builder

# Set the working directory for the Rust build
WORKDIR /backend

# Copy the entire project directory into the container
COPY . .

# Build the project in release mode
RUN cargo build

# Use a smaller image for the final runtime environment
FROM debian:buster-slim

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y libssl-dev && rm -rf /var/lib/apt/lists/*

# Set the working directory for the runtime container
WORKDIR /backend

# Copy only the necessary files from the builder stage
COPY --from=builder /backend/src/target/release/Athlead /usr/local/bin/backend

# Expose the port your application runs on
EXPOSE 8080

# Run the backend binary
CMD ["backend"]
