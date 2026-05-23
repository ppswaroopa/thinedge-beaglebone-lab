import logging

from metrics.cpu import collect_cpu
from metrics.disk import collect_disk
from metrics.memory import collect_memory
from metrics.network import collect_ip_address
from metrics.uptime import collect_uptime

COLLECTORS = [
    collect_cpu,
    collect_memory,
    collect_uptime,
    collect_disk,
    collect_ip_address,
]


def collect_metrics():
    metrics = []

    for collector in COLLECTORS:
        try:
            metrics.append(collector())
        except Exception:
            logging.exception("Metric collector failed: %s", collector.__name__)

    return metrics
