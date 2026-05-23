import psutil


def collect_memory():
    return {
        "name": "memory",
        "value": psutil.virtual_memory().percent,
        "unit": "percent",
    }
