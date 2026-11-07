"""Run with python3 -m unittest discover -s tests -v (Bash required).

Service control and public IP queries are mocked; no system configuration is edited.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which("bash") or "C:/Program Files/Git/bin/bash.exe"
SETTINGS = {
    "ipv4": ("0.0.0.0", False),
    "ipv6": ("::", True),
    "dual": ("::", False),
}


class InboundTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.config = self.path / "config.json"
        self.backups = self.path / "backups"
        self.calls = self.path / "calls"
        self.original = {
            "server": "0.0.0.0", "server_port": 7658,
            "password": "test-secret", "method": "chacha20-ietf-poly1305",
            "mode": "tcp_and_udp", "outbound_bind_addr": "192.0.2.9",
            "extra": {"preserve": True},
        }
        self.write_config(self.original)
        source = (ROOT / "ssmenu").read_text(encoding="utf-8")
        self.library = self.path / "library.sh"
        self.library.write_text(source.rsplit('\nmain "$@"', 1)[0] + "\n", encoding="utf-8")

    def write_config(self, data):
        self.config.write_text(json.dumps(data) + "\n", encoding="utf-8")

    def run_shell(self, command, answer="", **extra):
        env = os.environ.copy()
        env.update({
            "TEST_LIBRARY": self.library.as_posix(),
            "TEST_CONFIG": self.config.as_posix(),
            "TEST_BACKUPS": self.backups.as_posix(),
            "TEST_CALLS": self.calls.as_posix(),
            "TEST_MARKER": (self.path / "failed-once").as_posix(),
            "TEST_PYTHON": Path(sys.executable).as_posix(),
            "PYTHONIOENCODING": "utf-8",
        })
        env.update(extra)
        script = r'''
source "$TEST_LIBRARY"
CONFIG="$TEST_CONFIG"
BACKUP_DIR="$TEST_BACKUPS"
python3() { "$TEST_PYTHON" "$@" | tr -d '\r'; }
sleep() { :; }
qrencode() { :; }
public_ip4() { printf '%s' "${TEST_IP4-192.0.2.1}"; }
public_ip6() { printf '%s' "${TEST_IP6-2001:db8::1}"; }
systemctl() {
  echo "$*" >> "$TEST_CALLS"
  if [[ "${TEST_FAIL-}" == "$1" && ! -f "$TEST_MARKER" ]]; then
    touch "$TEST_MARKER"
    return 1
  fi
  return 0
}
''' + command
        result = subprocess.run([BASH, "--noprofile", "--norc", "-c", script],
                                input=answer.encode("utf-8"),
                                capture_output=True, env=env, timeout=30)
        result.stdout = result.stdout.decode("utf-8")
        result.stderr = result.stderr.decode("utf-8")
        return result

    def test_all_mode_transitions_preserve_other_settings(self):
        for previous, (address, only) in SETTINGS.items():
            for choice, mode in enumerate(SETTINGS, 1):
                with self.subTest(previous=previous, mode=mode):
                    before = dict(self.original, server=address, ipv6_only=only)
                    self.write_config(before)
                    result = self.run_shell("choose_inbound", f"{choice}\n")
                    self.assertEqual(result.returncode, 0, result.stderr)
                    expected = dict(before, server=SETTINGS[mode][0], ipv6_only=SETTINGS[mode][1])
                    self.assertEqual(json.loads(self.config.read_text()), expected)
        self.assertEqual(len(list(self.backups.glob("*.json"))), 9)
        if os.name != "nt":
            self.assertEqual(self.config.stat().st_mode & 0o777, 0o600)
            for backup in self.backups.glob("*.json"):
                self.assertEqual(backup.stat().st_mode & 0o777, 0o600)

    def test_backup_contains_original_bytes(self):
        before = self.config.read_bytes()
        result = self.run_shell("choose_inbound", "3\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(next(self.backups.glob("*.json")).read_bytes(), before)

    def test_cancel_invalid_and_eof_do_not_change_config(self):
        before = self.config.read_bytes()
        for answer in ("0\n", "9\n", "\n", ""):
            with self.subTest(answer=answer):
                self.run_shell("choose_inbound", answer)
                self.assertEqual(self.config.read_bytes(), before)
                self.assertFalse(self.calls.exists())
                self.assertFalse(self.backups.exists())

    def test_unsupported_or_invalid_config_is_untouched(self):
        cases = ["not json", "[]", json.dumps(dict(self.original, servers=[])),
                 json.dumps(dict(self.original, server="example.com"))]
        for content in cases:
            with self.subTest(content=content):
                self.config.write_text(content)
                result = self.run_shell("choose_inbound", "3\n")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.config.read_text(), content)
                self.assertFalse(self.calls.exists())

    def test_missing_config(self):
        self.config.unlink()
        result = self.run_shell("choose_inbound", "3\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.calls.exists())

    def test_backup_failure_does_not_change_config(self):
        self.backups.write_text("not a directory")
        before = self.config.read_bytes()
        result = self.run_shell("choose_inbound", "3\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.config.read_bytes(), before)
        self.assertFalse(self.calls.exists())

    def test_restart_failure_rolls_back(self):
        self.check_rollback("restart")

    def test_service_exiting_after_restart_rolls_back(self):
        self.check_rollback("is-active")

    def check_rollback(self, fail):
        before = self.config.read_bytes()
        result = self.run_shell("choose_inbound", "3\n", TEST_FAIL=fail)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.config.read_bytes(), before)
        self.assertEqual(self.calls.read_text().count("restart "), 2)

    def test_links_match_listener_family(self):
        for mode, (address, only) in SETTINGS.items():
            with self.subTest(mode=mode):
                self.write_config(dict(self.original, server=address, ipv6_only=only))
                result = self.run_shell("show_ss_url")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual("@192.0.2.1:7658" in result.stdout, mode != "ipv6")
                self.assertEqual("@[2001:db8::1]:7658" in result.stdout, mode != "ipv4")

    def test_ipv6_missing_does_not_fall_back_to_ipv4(self):
        self.write_config(dict(self.original, server="::", ipv6_only=True))
        result = self.run_shell("show_ss_url", TEST_IP6="")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("ss://", result.stdout)

    def test_dual_stack_generates_available_address(self):
        self.write_config(dict(self.original, server="::", ipv6_only=False))
        result = self.run_shell("show_ss_url", TEST_IP6="")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("@192.0.2.1:7658", result.stdout)
        self.assertNotIn("@[", result.stdout)

    def test_ss2022_encoding_is_preserved(self):
        self.write_config(dict(self.original, server="::", ipv6_only=True,
                               method="2022-blake3-aes-128-gcm", password="a+b/c="))
        result = self.run_shell("show_ss_url")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ss://2022-blake3-aes-128-gcm:a%2Bb%2Fc%3D@[2001:db8::1]:7658", result.stdout)


if __name__ == "__main__":
    unittest.main()
