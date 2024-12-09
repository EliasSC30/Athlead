# Use an official Rust image as the base for building
FROM rust:latest AS builder

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the Backend source code into the container
COPY . ./Backend

# Navigate to the Backend directory
WORKDIR /usr/src/app/Backend

# Build the Rust project in release mode
RUN cargo build --release

# Use a lightweight image for the final stage
FROM debian:buster-slim

# Set the working directory for the runtime container
WORKDIR /usr/src/app

# Copy the built binary from the builder stage
COPY --from=builder /usr/src/app/Backend/target/release/Athlead /usr/local/bin/backend

# Expose the port your application runs on (update as needed)
EXPOSE 8080

# Run the backend binary
CMD ["backend"]
