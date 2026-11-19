#!/usr/bin/env python3
import sys
from datetime import datetime

ENIP_COMMANDS = {
    "0x0004": "ListServices",
    "0x0063": "ListIdentity",
    "0x0064": "ListInterfaces",
    "0x0065": "RegisterSession",
    "0x0066": "UnregisterSession",
    "0x006f": "SendRRData",
    "0x0070": "SendUnitData",
}

CIP_SERVICES = {
    "0x0a": "MultipleService",
    "0x0e": "GetAttributeSingle",
    "0x10": "SetAttributeSingle",
    "0x4c": "ReadTag",
    "0x4d": "WriteTag",
    "0x4e": "ReadTagFragmented",
    "0x4f": "WriteTagFragmented",
}

def fmt_ts(epoch_str: str) -> str:
    try:
        dt = datetime.fromtimestamp(float(epoch_str))
        return dt.strftime("%H:%M:%S.%f")[:-3]
    except (ValueError, OSError):
        return epoch_str or "--:--:--.---"

def fmt_hex_code(val: str, mapping: dict[str, str], label: str) -> str:
    val = val.strip().lower()
    if not val:
        return ""
    if not val.startswith("0x") and val.isdigit():
        val = f"0x{int(val):02x}"
    name = mapping.get(val)
    return f"{name} ({val})" if name else f"{label}({val})"

def main() -> None:
    for line in sys.stdin:
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 8:
            continue

        ts, src, dst, enip_cmd, session, status, cip_svc, ioi_path = parts[:8]
        if not src and not dst and not enip_cmd:
            continue

        cmd_str = fmt_hex_code(enip_cmd, ENIP_COMMANDS, "ENIP")
        svc_str = fmt_hex_code(cip_svc, CIP_SERVICES, "CIP")

        details = []
        if cmd_str:
            details.append(cmd_str)
        if svc_str:
            details.append(f"-> {svc_str}")
        if ioi_path:
            details.append(f"path={ioi_path}")
        if session and session != "0x00000000":
            details.append(f"sess={session}")
        if status and status not in ("0", "0x00000000"):
            details.append(f"status={status}")

        summary = " | ".join(details) if details else "ENIP/CIP frame"
        print(f"{fmt_ts(ts)} | {src} -> {dst} | {summary}", flush=True)

if __name__ == "__main__":
    main()
