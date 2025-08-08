import os
import json
import base64
from uuid import uuid4
from typing import Dict, Any, Optional
from urllib.parse import unquote

def ensure_configs_dir() -> None:
    if not os.path.isdir('configs'):
        os.mkdir('configs')

def json_file_maker(data: Dict[str, Any]) -> str:
    ensure_configs_dir()
    file = f"configs/{uuid4().hex[:8]}.json"
    # Write compact first (for atomicity), then pretty-print and overwrite
    with open(file, 'w') as outfile:
        json.dump(data, outfile)
    # Now pretty-print and overwrite
    with open(file, 'r') as infile:
        obj = json.load(infile)
    with open(file, 'w') as outfile:
        json.dump(obj, outfile, indent=4, sort_keys=True)
    return file

def parse_uri(uri: str) -> Dict[str, Any]:
    """Parse the URI into its components and query parameters. All param values are URL-decoded."""
    try:
        protocol, rest = uri.split('://', 1)
        userinfo, hostinfo = rest.split('@', 1)
        if ':' not in hostinfo:
            raise ValueError('Invalid URI: missing port')
        address, port_and_query = hostinfo.split(':', 1)
        if '?' in port_and_query:
            port, query = port_and_query.split('?', 1)
        elif '#' in port_and_query:
            port, query = port_and_query.split('#', 1)
        else:
            port, query = port_and_query, ''
        port = int(port)
        # Parse query parameters and URL-decode values
        params = {}
        for part in query.replace('#', '&').split('&'):
            if '=' in part:
                k, v = part.split('=', 1)
                params[k] = unquote(v)
        return {
            'protocol': protocol,
            'userinfo': userinfo,
            'address': address,
            'port': port,
            'params': params
        }
    except Exception as e:
        print(f"[ERROR] Failed to parse URI: {e}")
        raise

def get_param(params: Dict[str, str], key: str, default: str = "") -> str:
    return params.get(key, default)

def inbound_generator(host: str, port: int, socksport: int) -> Dict[str, Any]:
    return {
        "inbounds": [
            {
                "tag": "socks",
                "port": socksport,
                "listen": host,
                "protocol": "socks",
                "sniffing": {
                    "enabled": True,
                    "destOverride": ["http", "tls"],
                    "routeOnly": False
                },
                "settings": {
                    "auth": "noauth",
                    "udp": True,
                    "allowTransparent": False
                }
            },
            {
                "tag": "http",
                "port": port,
                "listen": host,
                "protocol": "http",
                "sniffing": {
                    "enabled": True,
                    "destOverride": ["http", "tls"],
                    "routeOnly": False
                },
                "settings": {
                    "auth": "noauth",
                    "udp": True,
                    "allowTransparent": False
                }
            }
        ]
    }

def convert_uri_reality_json(host: str, port: int, socksport: int, uri: str) -> str:
    try:
        parsed = parse_uri(uri)
        params = parsed['params']
        data = {
            "log": {"access": "", "error": "", "loglevel": "warning"},
            "outbounds": [
                {
                    "tag": "proxy",
                    "protocol": parsed['protocol'],
                    "settings": {
                        "vnext": [
                            {
                                "address": parsed['address'],
                                "port": parsed['port'],
                                "users": [
                                    {
                                        "id": parsed['userinfo'],
                                        "alterId": 0,
                                        "email": "t@t.tt",
                                        "security": "auto",
                                        "encryption": "none",
                                        "flow": get_param(params, "flow")
                                    }
                                ]
                            }
                        ]
                    },
                    "streamSettings": {
                        "network": get_param(params, "type"),
                        "security": get_param(params, "security"),
                        "realitySettings": {
                            "serverName": get_param(params, "sni"),
                            "fingerprint": get_param(params, "fp"),
                            "show": False,
                            "publicKey": get_param(params, "pbk"),
                            "shortId": get_param(params, "sid"),
                            "spiderX": get_param(params, "spx")
                        }
                    },
                    "mux": {"enabled": False, "concurrency": -1}
                },
                {"tag": "direct", "protocol": "freedom", "settings": {}},
                {"tag": "block", "protocol": "blackhole", "settings": {"response": {"type": "http"}}}
            ]
        }
        # Optional TCP headers
        if "host" in params:
            headertype = get_param(params, "headertype", "http")
            path = [get_param(params, "path", "/")]
            data['outbounds'][0]['streamSettings']["tcpSettings"] = {
                "header": {
                    "type": headertype,
                    "request": {
                        "version": "1.1",
                        "method": "GET",
                        "path": path,
                        "headers": {
                            "Host": [params["host"]],
                            "User-Agent": [""],
                            "Accept-Encoding": ["gzip, deflate"],
                            "Connection": ["keep-alive"],
                            "Pragma": "no-cache"
                        }
                    }
                }
            }
        # Optional gRPC
        if get_param(params, "type") == "grpc":
            data['outbounds'][0]['streamSettings']["grpcSettings"] = {
                "serviceName": get_param(params, "serviceName"),
                "multiMode": False,
                "idle_timeout": 60,
                "health_check_timeout": 20,
                "permit_without_stream": False,
                "initial_windows_size": 0
            }
        data.update(inbound_generator(host, port, socksport))
        return json_file_maker(data)
    except Exception as e:
        print(f"[ERROR] convert_uri_reality_json: {e}")
        return ''

def convert_uri_vless_ws_json(host: str, port: int, socksport: int, uri: str) -> str:
    try:
        parsed = parse_uri(uri)
        params = parsed['params']
        headers = {"Host": get_param(params, "host")} if "host" in params else {}
        path = get_param(params, "path")
        data = {
            "log": {"access": "", "error": "", "loglevel": "warning"},
            "outbounds": [
                {
                    "tag": "proxy",
                    "protocol": parsed['protocol'],
                    "settings": {
                        "vnext": [
                            {
                                "address": parsed['address'],
                                "port": parsed['port'],
                                "users": [
                                    {
                                        "id": parsed['userinfo'],
                                        "alterId": 0,
                                        "email": "t@t.tt",
                                        "security": "auto",
                                        "encryption": "none",
                                        "flow": ""
                                    }
                                ]
                            }
                        ]
                    },
                    "streamSettings": {
                        "network": get_param(params, "type"),
                        "wsSettings": {
                            "path": path,
                            "headers": headers
                        }
                    },
                    "mux": {"enabled": False, "concurrency": -1}
                },
                {"tag": "direct", "protocol": "freedom", "settings": {}},
                {"tag": "block", "protocol": "blackhole", "settings": {"response": {"type": "http"}}}
            ]
        }
        if "security" in params and params["security"] != "none":
            sni = get_param(params, "sni")
            alpn = [alpn for alpn in get_param(params, "alpn").split(',') if alpn] if "alpn" in params else []
            data['outbounds'][0]['streamSettings'].update({
                "security": params["security"],
                "tlsSettings": {
                    "allowInsecure": True,
                    "serverName": sni,
                    "alpn": alpn,
                    "show": False
                }
            })
        data.update(inbound_generator(host, port, socksport))
        return json_file_maker(data)
    except Exception as e:
        print(f"[ERROR] convert_uri_vless_ws_json: {e}")
        return ''

# ... (You can continue this pattern for the other convert_uri_* functions, using the helpers above) ... 