# Use an official Python runtime as the base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake g++ make libgmp-dev libssl-dev git python3-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Clone and Build OpenFHE (Using Your Method)
RUN git clone https://github.com/openfheorg/openfhe-development.git && \
    cd openfhe-development && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_EXAMPLES=OFF && \
    make -j$(nproc)

# Set OpenFHE Library Path (Your Method)
ENV LD_LIBRARY_PATH=/app/openfhe-development/build/lib

# Install Python dependencies
RUN pip install --no-cache-dir fastapi uvicorn pydantic

# Copy C++ encryption source code
COPY claude.cpp /app/claude.cpp

# Compile C++ encryption binary using OpenFHE build directory
RUN g++ -o /app/encrypt_vote /app/claude.cpp \
    -I/app/openfhe-development/src/core/include \
    -I/app/openfhe-development/src/pke/include \
    -I/app/openfhe-development/src/binfhe/include \
    -I/app/openfhe-development/build/src/core \  
    -I/app/openfhe-development/third-party/cereal/include \
    -L/app/openfhe-development/build/lib \
    -lOPENFHEcore -lOPENFHEpke -lOPENFHEbinfhe -std=c++17

# Ensure the compiled binary is executable
RUN chmod +x /app/encrypt_vote

# Copy Python FastAPI server code
COPY server.py /app/server.py

# Expose FastAPI port
EXPOSE 8000

# Start the FastAPI server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
