FROM mongo:7.0
RUN apt-get update && apt-get install -y awscli && rm -rf /var/lib/apt/lists/*

