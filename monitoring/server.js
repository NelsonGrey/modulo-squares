#!/usr/bin/env node

// Simple monitoring server for GitHub Runner status
// Provides health check and token status endpoints

const express = require('express');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.MONITORING_PORT || 8080;

// Path to environment file
const ENV_FILE = path.join(__dirname, '..', '.env.runner');

// Middleware
app.use(express.static(path.join(__dirname, 'monitoring')));

// Health check endpoint
app.get('/health', (req, res) => {
    try {
        // Check if Docker is running
        execSync('docker info', { stdio: 'pipe' });

        // Check if runner container is running
        const containers = execSync('docker ps --format "{{.Names}}"', { encoding: 'utf8' });
        if (!containers.includes('modulo-squares-runner')) {
            return res.status(503).json({ status: 'unhealthy', message: 'Runner container not running' });
        }

        // Check if runner process is running inside container
        const processes = execSync('docker exec modulo-squares-runner ps aux', { encoding: 'utf8' });
        if (!processes.includes('Runner.Listener')) {
            return res.status(503).json({ status: 'unhealthy', message: 'Runner process not running' });
        }

        res.json({ status: 'healthy', message: 'Runner is operational' });
    } catch (error) {
        console.error('Health check failed:', error.message);
        res.status(503).json({ status: 'unhealthy', message: error.message });
    }
});

// Token status endpoint
app.get('/token-status', (req, res) => {
    try {
        if (!fs.existsSync(ENV_FILE)) {
            return res.status(500).json({ valid: false, error: 'Environment file not found' });
        }

        const envContent = fs.readFileSync(ENV_FILE, 'utf8');
        const tokenMatch = envContent.match(/^RUNNER_TOKEN=(.+)$/m);

        if (!tokenMatch) {
            return res.status(500).json({ valid: false, error: 'Token not found in environment file' });
        }

        const token = tokenMatch[1];

        // For now, we'll assume the token is valid if it exists
        // In a real implementation, you might want to validate with GitHub API
        // But that would require the GITHUB_PAT which we don't want to expose

        // Check last updated timestamp
        const updatedMatch = envContent.match(/^# Last updated:\s*(.+)$/m);
        const lastUpdated = updatedMatch ? new Date(updatedMatch[1]) : new Date();

        // Estimate expiration (GitHub tokens typically last ~1 year)
        const expiresAt = new Date(lastUpdated.getTime() + (365 * 24 * 60 * 60 * 1000));

        res.json({
            valid: true,
            expires_at: expiresAt.toISOString(),
            last_updated: lastUpdated.toISOString()
        });
    } catch (error) {
        console.error('Token status check failed:', error.message);
        res.status(500).json({ valid: false, error: error.message });
    }
});

// Logs endpoint
app.get('/logs', (req, res) => {
    try {
        const logFile = '/tmp/runner-token-refresh.log';
        if (fs.existsSync(logFile)) {
            const logs = fs.readFileSync(logFile, 'utf8');
            res.type('text/plain').send(logs);
        } else {
            res.status(404).send('Log file not found');
        }
    } catch (error) {
        res.status(500).send('Error reading logs: ' + error.message);
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Monitoring server running on port ${PORT}`);
    console.log(`📊 Status dashboard: http://localhost:${PORT}`);
    console.log(`💚 Health endpoint: http://localhost:${PORT}/health`);
    console.log(`🔑 Token status: http://localhost:${PORT}/token-status`);
    console.log(`📋 Logs: http://localhost:${PORT}/logs`);
});