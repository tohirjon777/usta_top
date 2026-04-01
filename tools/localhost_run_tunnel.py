#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import pty
import re
import selectors
import signal
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse


URL_PATTERN = re.compile(r"tunneled with tls termination,\s*(https://[^\s]+)")


class TunnelDaemon:
    def __init__(self, local_url: str, log_file: Path, url_file: Path) -> None:
        self.local_url = local_url
        self.log_file = log_file
        self.url_file = url_file
        self.child: subprocess.Popen[str] | None = None
        self.master_fd: int | None = None
        self.running = True

    def install_signal_handlers(self) -> None:
        signal.signal(signal.SIGTERM, self._handle_stop)
        signal.signal(signal.SIGINT, self._handle_stop)

    def _handle_stop(self, _signum: int, _frame) -> None:
        self.running = False
        self._terminate_child()

    def _terminate_child(self) -> None:
        if self.child is None:
            return
        if self.child.poll() is None:
            try:
                self.child.terminate()
                self.child.wait(timeout=5)
            except Exception:
                try:
                    self.child.kill()
                except Exception:
                    pass

    def run(self) -> int:
        self.install_signal_handlers()
        self.log_file.parent.mkdir(parents=True, exist_ok=True)
        self.url_file.parent.mkdir(parents=True, exist_ok=True)
        parsed = urlparse(self.local_url)
        tunnel_host = parsed.hostname or "127.0.0.1"
        tunnel_port = parsed.port or 8080

        with self.log_file.open("a", encoding="utf-8", buffering=1) as log_handle:
            master_fd, slave_fd = pty.openpty()
            self.master_fd = master_fd

            cmd = [
                "/usr/bin/ssh",
                "-tt",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "ExitOnForwardFailure=yes",
                "-o",
                "ServerAliveInterval=30",
                "-R",
                f"80:{tunnel_host}:{tunnel_port}",
                "nokey@localhost.run",
            ]

            self.child = subprocess.Popen(
                cmd,
                stdin=slave_fd,
                stdout=slave_fd,
                stderr=slave_fd,
                text=False,
                start_new_session=True,
                close_fds=True,
            )
            os.close(slave_fd)

            selector = selectors.DefaultSelector()
            selector.register(master_fd, selectors.EVENT_READ)
            pending = ""

            while self.running:
                if self.child.poll() is not None:
                    break

                events = selector.select(timeout=1.0)
                if not events:
                    continue

                for key, _mask in events:
                    try:
                        chunk = os.read(key.fd, 4096)
                    except OSError:
                        chunk = b""

                    if not chunk:
                        continue

                    text = chunk.decode("utf-8", errors="ignore")
                    log_handle.write(text)
                    pending += text

                    match = URL_PATTERN.search(pending)
                    if match:
                        self.url_file.write_text(match.group(1), encoding="utf-8")

                    if len(pending) > 16000:
                        pending = pending[-8000:]

            selector.close()
            try:
                os.close(master_fd)
            except OSError:
                pass

        self._terminate_child()
        return self.child.returncode if self.child and self.child.returncode is not None else 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--local-url", required=True)
    parser.add_argument("--log-file", required=True)
    parser.add_argument("--url-file", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    daemon = TunnelDaemon(
        local_url=args.local_url,
        log_file=Path(args.log_file),
        url_file=Path(args.url_file),
    )
    return daemon.run()


if __name__ == "__main__":
    sys.exit(main())
