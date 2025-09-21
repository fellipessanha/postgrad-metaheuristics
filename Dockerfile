# Use the official Julia image
FROM julia:1.11

# Set the working directory
WORKDIR /app

# Copy the Exercises module
COPY Implementation/ ./Implementation/

# Set working directory to Implementation
WORKDIR /app/Implementation

# Install dependencies and precompile
RUN julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

# Set the default command to run Julia with the project
CMD ["julia", "--project=."]