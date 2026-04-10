from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from datetime import datetime
import os
import socket

app = FastAPI(
    title="FastAPI Demo App",
    description="Simple FastAPI application deployed with Azure CI/CD to AWS EC2",
    version="1.0.0"
)


@app.get("/", response_class=HTMLResponse)
async def home():
    """Home page with app info"""
    hostname = socket.gethostname()
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>FastAPI Demo App</title>
        <style>
            body {{
                font-family: 'Segoe UI', Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
            }}
            .container {{
                background: white;
                border-radius: 15px;
                padding: 40px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            }}
            h1 {{ color: #333; margin-bottom: 10px; }}
            .subtitle {{ color: #666; margin-bottom: 30px; }}
            .info-box {{
                background: #f8f9fa;
                border-left: 4px solid #667eea;
                padding: 15px 20px;
                margin: 15px 0;
                border-radius: 0 8px 8px 0;
            }}
            .label {{ font-weight: bold; color: #555; }}
            .endpoints {{
                background: #282c34;
                color: #abb2bf;
                padding: 20px;
                border-radius: 8px;
                font-family: 'Consolas', monospace;
            }}
            .endpoints a {{ color: #61afef; }}
            .badge {{
                display: inline-block;
                background: #28a745;
                color: white;
                padding: 5px 15px;
                border-radius: 20px;
                font-size: 14px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <span class="badge">🚀 Running</span>
            <h1>FastAPI Demo Application</h1>
            <p class="subtitle">Deployed via Azure DevOps CI/CD Pipeline to AWS EC2</p>
            
            <div class="info-box">
                <span class="label">Hostname:</span> {hostname}
            </div>
            <div class="info-box">
                <span class="label">Server Time:</span> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
            </div>
            <div class="info-box">
                <span class="label">Environment:</span> {os.getenv('ENVIRONMENT', 'development')}
            </div>
            <div class="info-box">
                <span class="label">Version:</span> 1.0.0
            </div>
            
            <h3>📡 Available Endpoints</h3>
            <div class="endpoints">
                GET  /           → This page<br>
                GET  /health     → Health check<br>
                GET  /api/info   → JSON app info<br>
                GET  /docs       → <a href="/docs">Swagger UI</a><br>
                GET  /redoc      → <a href="/redoc">ReDoc</a>
            </div>
        </div>
    </body>
    </html>
    """


@app.get("/api/info")
async def api_info():
    """API endpoint returning app information"""
    return {
        "app": "FastAPI Demo App",
        "version": "1.0.0",
        "hostname": socket.gethostname(),
        "timestamp": datetime.now().isoformat(),
        "environment": os.getenv("ENVIRONMENT", "development"),
        "deployed_via": "Azure DevOps CI/CD"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for load balancers and monitoring"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
