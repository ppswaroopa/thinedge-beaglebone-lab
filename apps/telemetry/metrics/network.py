import socket


def collect_ip_address():
    ip_address = "unknown"

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.connect(("8.8.8.8", 80))
            ip_address = sock.getsockname()[0]
    except OSError:
        pass

    return {
        "name": "ip_address",
        "value": ip_address,
        "unit": "address",
    }
