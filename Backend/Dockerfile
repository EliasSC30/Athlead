# Use the official Rust image as a builder
FROM rust:latest AS builder

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the entire Backend directory into the container
COPY ./Backend ./Backend

# Navigate to the Backend directory
WORKDIR /usr/src/app/Backend

# Build the Rust application in release mode
RUN cargo build --release

# Use a smaller base image for the final stage
FROM debian:buster-slim

# Set the working directory for the runtime container
WORKDIR /usr/src/app

# Copy the compiled binary from the builder stage
COPY --from=builder /usr/src/app/Backend/target/release/Athlead /usr/local/bin/backend

# Expose the port the backend listens on (update if needed)
EXPOSE 8080

# Run the backend binary
CMD ["backend"]
