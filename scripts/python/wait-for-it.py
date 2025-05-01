#!/usr/bin/env python3
import socket
import sys
import time
import argparse

def wait_for_port(host, port, timeout=60):
    start_time = time.time()
    while True:
        try:
            socket.create_connection((host, port), timeout=1)
            print(f"El servicio en {host}:{port} está disponible")
            return True
        except socket.error:
            if time.time() - start_time >= timeout:
                print(f"Timeout esperando por {host}:{port}")
                return False
            time.sleep(1)
            print(f"Esperando por {host}:{port}...")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('hostport', help='Host y puerto en formato host:puerto')
    parser.add_argument('-t', '--timeout', type=int, default=60,
                        help='Tiempo de espera en segundos (default: 60)')
    args = parser.parse_args()

    host, port = args.hostport.split(':')
    port = int(port)

    if not wait_for_port(host, port, args.timeout):
        sys.exit(1)

if __name__ == '__main__':
    main()