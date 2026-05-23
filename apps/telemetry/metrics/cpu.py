import psutil


def collect_cpu():
    return {
        "name": "cpu",
        "value": psutil.cpu_percent(interval=None),
        "unit": "percent",
    }
