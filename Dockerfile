# Use the Rust official image as the base image
FROM rust:latest

# Set the working directory
WORKDIR /Backend

# Copy the project files
COPY . .

# Build the Rust project
RUN cargo build --release

# Expose the application's port
EXPOSE 8080

# Run the built binary
CMD ["./target/release/Athlead"]
