# Use an official Rust image as the base for building
FROM rust:latest AS builder

# Copy the entire project directory into the container
COPY ./ ./

# Build the project in release mode
RUN cargo build

# Expose the port your application runs on
EXPOSE 8080

# Run the backend binary
CMD ["./target/debug/Athlead"]
