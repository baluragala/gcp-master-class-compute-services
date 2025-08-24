#!/bin/bash

# Update system packages
apt-get update -y

# Install nginx
apt-get install -y nginx

# Get instance metadata
INSTANCE_NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
INSTANCE_ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d'/' -f4)
INSTANCE_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

# Create custom HTML page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>High Availability Web Server</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 15px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
            margin: 20px;
        }
        .server-badge {
            background: #4CAF50;
            color: white;
            padding: 10px 20px;
            border-radius: 25px;
            display: inline-block;
            margin-bottom: 20px;
            font-weight: bold;
            font-size: 18px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 30px;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .info-label {
            font-weight: bold;
            color: #333;
            margin-bottom: 5px;
        }
        .info-value {
            color: #666;
            font-family: monospace;
            background: #e9ecef;
            padding: 5px 10px;
            border-radius: 5px;
            word-break: break-all;
        }
        .timestamp {
            margin-top: 30px;
            color: #888;
            font-size: 14px;
        }
        .load-balancer-info {
            background: #e3f2fd;
            border: 2px solid #2196F3;
            border-radius: 10px;
            padding: 20px;
            margin-top: 20px;
        }
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            background: #4CAF50;
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="server-badge">
            <span class="status-indicator"></span>
            Server: $INSTANCE_NAME
        </div>
        
        <h1>🚀 High Availability Web Infrastructure</h1>
        <p>This page is served by a load-balanced, auto-scaling infrastructure on Google Cloud Platform.</p>
        
        <div class="load-balancer-info">
            <h3>📊 Load Balancer Status</h3>
            <p>You are currently being served by one of multiple backend instances. Refresh the page to see load balancing in action!</p>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <div class="info-label">Instance Name</div>
                <div class="info-value">$INSTANCE_NAME</div>
            </div>
            <div class="info-card">
                <div class="info-label">Zone</div>
                <div class="info-value">$INSTANCE_ZONE</div>
            </div>
            <div class="info-card">
                <div class="info-label">Internal IP</div>
                <div class="info-value">$INSTANCE_IP</div>
            </div>
            <div class="info-card">
                <div class="info-label">External IP</div>
                <div class="info-value">$EXTERNAL_IP</div>
            </div>
        </div>
        
        <div class="timestamp">
            Page generated at: $(date)
        </div>
        
        <div style="margin-top: 30px; padding: 20px; background: #fff3cd; border-radius: 10px; border-left: 4px solid #ffc107;">
            <h4>🏗️ Infrastructure Features</h4>
            <ul style="text-align: left; display: inline-block;">
                <li>Auto-scaling managed instance group</li>
                <li>HTTP load balancer with health checks</li>
                <li>Multi-zone deployment for high availability</li>
                <li>Automatic instance replacement on failure</li>
                <li>Custom VPC with security groups</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Create a health check endpoint
cat > /var/www/html/health << EOF
OK
EOF

# Configure nginx
systemctl enable nginx
systemctl start nginx

# Create a simple API endpoint to show server info
mkdir -p /var/www/html/api
cat > /var/www/html/api/info.json << EOF
{
    "server": "$INSTANCE_NAME",
    "zone": "$INSTANCE_ZONE",
    "internal_ip": "$INSTANCE_IP",
    "external_ip": "$EXTERNAL_IP",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "healthy"
}
EOF

# Log the startup completion
echo "$(date): Web server setup completed for instance $INSTANCE_NAME" >> /var/log/startup-script.log
