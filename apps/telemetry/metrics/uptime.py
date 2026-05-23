import time

import psutil


def collect_uptime():
    return {
        "name": "uptime",
        "value": int(time.time() - psutil.boot_time()),
        "unit": "seconds",
    }
