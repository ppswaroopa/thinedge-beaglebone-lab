import psutil


def collect_disk():
    return {
        "name": "disk",
        "value": psutil.disk_usage("/").percent,
        "unit": "percent",
    }
