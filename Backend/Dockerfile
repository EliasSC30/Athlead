# Use an official Rust image as the base for building
FROM rust:latest AS builder

# Set the working directory for the Rust build
WORKDIR /usr/src/app

# Copy the entire project directory into the container
COPY . .

# Build the project (the default Rust build target is assumed here; adjust if needed)
RUN cargo build --release

# Use a smaller image for the final runtime environment
FROM debian:buster-slim

# Set the working directory for the runtime container
WORKDIR /usr/src/app

# Copy only the necessary files from the builder stage
COPY --from=builder /usr/src/app/target/release/Athlead /usr/local/bin/backend

# Expose the port your application runs on (adjust as necessary)
EXPOSE 8080

# Run the backend binary
CMD ["backend"]
