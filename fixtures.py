#!/usr/bin/env python3
"""SR rehearsal fixtures (deterministic, stdlib only). Used by tests in the DISPOSABLE sandbox repo only.
  fail   : always fails (red-main drill, C12 smoke)
  flaky  : fails when sha-derived bucket == 0 (about 1 in 3), same sha -> same result; flip with SEED
  pass   : always passes (control)
Usage: fixtures.py <fail|flaky|pass> [--sha SHA] [--seed N]   exit 0 pass, 1 fail. Prints one JSON line."""
import hashlib, json, sys

def verdict(kind, sha="", seed=0):
    if kind == "fail":
        return False
    if kind == "pass":
        return True
    if kind == "flaky":
        n = int(hashlib.sha256(f"{seed}:{sha}".encode()).hexdigest(), 16)
        return n % 3 != 0
    raise SystemExit(f"unknown kind {kind}")

if __name__ == "__main__":
    a = sys.argv[1:]
    kind = a[0] if a else "pass"
    sha = a[a.index("--sha") + 1] if "--sha" in a else ""
    seed = int(a[a.index("--seed") + 1]) if "--seed" in a else 0
    ok = verdict(kind, sha, seed)
    print(json.dumps({"fixture": kind, "sha": sha, "seed": seed, "pass": ok}))
    sys.exit(0 if ok else 1)
