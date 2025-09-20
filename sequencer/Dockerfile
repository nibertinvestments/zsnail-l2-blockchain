# ZSnail L2 Blockchain Sequencer Docker Image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy application code
COPY index.js ./
COPY contracts/ ./contracts/

# Expose port 8545 (standard Ethereum RPC port)
EXPOSE 8545

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8545/health || exit 1

# Run the sequencer
CMD ["npm", "start"]