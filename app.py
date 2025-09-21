from flask import Flask, request, copy_current_request_context
from concurrent.futures import ThreadPoolExecutor
import gc
import os
import time
import requests
import tempfile
import mysql.connector

app = Flask(__name__)

def db_task():
    try:
        arg_duration = int(request.args.get("db_duration", 1))
        conn = mysql.connector.connect(
                host=os.getenv('DB_HOST'),
                port=int(os.getenv('DB_PORT')),
                user=os.getenv('DB_USERNAME'),
                password=os.getenv('DB_PASSWORD')
        )
        time.sleep(arg_duration)
        conn.close()
        return "<h1>DB connection completed</h1>", 200
    except Exception as e:
        return f"<h1>DB connection failed: {str(e)}</h1>", 500
def cpu_task():
    try:
        arg_duration = int(request.args.get("cpu_duration", 1))
        arg_range = int(request.args.get("cpu_range", 1))
        arg_interval = float(request.args.get("cpu_interval", 0.1))
        end_time = time.time() + arg_duration
        while time.time() < end_time:
            sum(i**2 for i in range(arg_range))
            time.sleep(arg_interval)
        return "<h1>CPU calculation completed</h1>", 200
    except Exception as e:
        return f"<h1>CPU calculation failed: {str(e)}</h1>", 500
def memory_task():
    try:
        arg_size = int(request.args.get("memory_size", 1))
        arg_range = int(request.args.get("memory_range", 1))
        arg_duration = int(request.args.get("memory_duration", 1))
        data = [bytearray(arg_size * 1024) for _ in range(arg_range)]
        time.sleep(arg_duration)
        del data
        gc.collect()
        return "<h1>Memory allocation completed</h1>", 200
    except Exception as e:
        return f"<h1>Memory allocation failed: {str(e)}</h1>", 500
def network_task():
    try:
        arg_duration = int(request.args.get("network_duration", 1))
        arg_interval = float(request.args.get("network_interval", 0.1))
        end_time = time.time() + arg_duration
        while time.time() < end_time:
            requests.get('https://api.github.com/', timeout=5)
            time.sleep(arg_interval)
        return "<h1>Network request completed</h1>", 200
    except Exception as e:
        return f"<h1>Network request failed: {str(e)}</h1>", 500
def disk_task():
    try:
        arg_duration = int(request.args.get("disk_duration", 1))
        arg_size = int(request.args.get("disk_size", 1))
        arg_interval = float(request.args.get("disk_interval", 0.1))
        end_time = time.time() + arg_duration
        data = bytearray(arg_size * 1024)
        while time.time() < end_time:
            with tempfile.NamedTemporaryFile(delete=True) as temp_file:
                temp_file.write(data)
                temp_file.flush()
                temp_file.seek(0)
                temp_file.read()
                time.sleep(arg_interval)
        del data
        gc.collect()
        return "<h1>Disk I/O completed</h1>", 200
    except Exception as e:
        return f"<h1>Disk I/O failed: {str(e)}</h1>", 500

@app.route('/')
def hello():
    return f"""
    <h1>Hello from Flask! Version: {os.getenv('APP_VERSION', 'v1.0')}</h1>
    <h2><a href="/event">Go to Event Page – Run All Tasks</a></h2>
    <ul>
        <li><a href="/db">Run DB Task</a></li>
        <li><a href="/cpu">Run CPU Task</a></li>
        <li><a href="/memory">Run Memory Task</a></li>
        <li><a href="/network">Run Network Task</a></li>
        <li><a href="/disk">Run Disk Task</a></li>
    </ul>
    """

@app.route('/event')
def event():
    with ThreadPoolExecutor(max_workers=5) as executor:
        wrapped_db_task = copy_current_request_context(db_task)
        wrapped_cpu_task = copy_current_request_context(cpu_task)
        wrapped_memory_task = copy_current_request_context(memory_task)
        wrapped_network_task = copy_current_request_context(network_task)
        wrapped_disk_task = copy_current_request_context(disk_task)
        futures = [
            executor.submit(wrapped_db_task),
            executor.submit(wrapped_cpu_task),
            executor.submit(wrapped_memory_task),
            executor.submit(wrapped_network_task),
            executor.submit(wrapped_disk_task)
        ]
        results = []
        for future in futures:
            result = future.result()
            results.append(result[0])
    return f"""
    <h1>All Tasks Results:</h1>
    {''.join(results)}
    <img src="/static/event.png">
    """

@app.route('/db')
def db():
    return db_task()

@app.route('/cpu')
def cpu():
    return cpu_task()

@app.route('/memory')
def memory():
    return memory_task()

@app.route('/network')
def network():
    return network_task()

@app.route('/disk')
def disk():
    return disk_task()