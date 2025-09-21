from flask import Flask
import os

health_app = Flask(__name__)

@health_app.route('/health')
def health():
    return {"status": "healthy", "version": os.getenv('APP_VERSION', 'v1.0')}