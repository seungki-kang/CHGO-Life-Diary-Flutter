"""Loopback synthetic fixture, not Auth0. No persistence or request-body logs.

Contract verified against JesusLife-One-API-ld-login/app/core/
life_diary_login.py and mobile_routes.py on 2026-11-09.
"""
import base64
import hashlib
import json
import re
import secrets
import time
import threading
import uuid
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlencode, urlsplit

PREFIX = '/api/v1/mobile/life-diary'
RETURN = 'jesuslife-life-diary-poc://auth/complete/android'
BINDING = dict(app_id='life_diary', client_id='synthetic-life-diary-debug', return_uri=RETURN)


class Fixture(ThreadingHTTPServer):
    allow_reuse_address = False

    def __init__(self, address=('127.0.0.1', 8000)):
        # Binding is the atomic port check: never stop or reuse another process.
        super().__init__(address, Handler)
        self.state_lock = threading.Lock()
        self.pending = {}
        self.sessions = {}
        self.counts = dict(start=0, authorize=0, exchange=0, session=0, logout=0, upload=0)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def setup(self):
        self.request.settimeout(5)
        super().setup()

    def reply(self, status, data=None, **headers):
        # Build the response under the state lock; socket I/O happens after release.
        payload = b'' if data is None else json.dumps(data).encode()
        return status, payload, {'Content-Type': 'application/json', **headers}

    def do_GET(self):
        try:
            status, payload, headers = self.dispatch()
            self.send_response(status)
            self.send_header('Cache-Control', 'no-store')
            self.send_header('Content-Length', str(len(payload)))
            for key, value in headers.items():
                self.send_header(key, value)
            self.end_headers()
            self.wfile.write(payload)
        except (TimeoutError, ConnectionError):
            self.close_connection = True

    do_POST = do_GET

    def dispatch(self):
        # Never hold the shared state lock while waiting for request bytes.
        data = {}
        if (self.command == 'POST' and urlsplit(self.path).path in
                (PREFIX + '/login-transactions', PREFIX + '/session-exchange')):
            try:
                size = int(self.headers.get('Content-Length', '0'))
                if not 0 < size <= 4096:
                    return self.reply(422)
                data = json.loads(self.rfile.read(size))
                if not isinstance(data, dict):
                    return self.reply(422)
            except (ValueError, TypeError, UnicodeError):
                return self.reply(422)
        with self.server.state_lock:
            return self.dispatch_state(data)

    def dispatch_state(self, data):
        url = urlsplit(self.path)
        route = (self.command, url.path)
        allowed = {('POST', PREFIX + '/login-transactions'): 'start',
                   ('GET', PREFIX + '/authorize'): 'authorize',
                   ('POST', PREFIX + '/session-exchange'): 'exchange',
                   ('GET', PREFIX + '/session'): 'session',
                   ('POST', PREFIX + '/logout'): 'logout'}
        if route == ('GET', '/__synthetic_stats'):
            return self.reply(200, dict(self.server.counts,
                fixture='life-diary-synthetic-v1'))
        kind = allowed.get(route)
        if kind is None:
            # Count every non-auth attempt conservatively as a potential upload.
            self.server.counts['upload'] += 1
            return self.reply(404)
        self.server.counts[kind] += 1
        try:
            if kind in ('start', 'exchange'):
                expected = set(BINDING) | ({'challenge'} if kind == 'start' else {'transaction', 'code', 'verifier'})
                if set(data) != expected or any(data.get(k) != v for k, v in BINDING.items()):
                    return self.reply(422)
            if kind == 'start':
                if not re.fullmatch(r'[A-Za-z0-9_-]{43}', data['challenge']):
                    return self.reply(422)
                state = secrets.token_urlsafe(32)
                transaction = str(uuid.uuid4())
                self.server.pending[state] = dict(transaction=transaction, challenge=data['challenge'],
                    code=secrets.token_urlsafe(32), deadline=time.time() + 300, authorized=False)
                # Public emulator port is fixed by the app allowlist. ADB may
                # forward it to a different host listener; never advertise that port.
                return self.reply(200, dict(transaction=transaction,
                    authorize_url='http://127.0.0.1:8000' + PREFIX + '/authorize?' + urlencode(dict(state=state))))
            if kind == 'authorize':
                query = parse_qs(url.query)
                if set(query) != {'state'} or len(query['state']) != 1:
                    return self.reply(401)
                item = self.server.pending.get(query['state'][0])
                if not item or item['authorized'] or item['deadline'] <= time.time():
                    return self.reply(401)
                item['authorized'] = True
                callback = RETURN + '?' + urlencode(dict(transaction=item['transaction'], code=item['code']))
                # Explicit browser click avoids browsers blocking automatic custom-scheme redirects.
                page = ('<!doctype html><meta name="viewport" content="width=device-width">'
                        '<h1>Synthetic authentication only</h1><a href="' + callback + '">Return to Life Diary</a>').encode()
                return 200, page, {'Content-Type': 'text/html; charset=utf-8'}
            if kind == 'exchange':
                state = next((s for s, p in self.server.pending.items() if p['transaction'] == data['transaction']), None)
                item = self.server.pending.pop(state, None)
                challenge = base64.urlsafe_b64encode(hashlib.sha256(data['verifier'].encode('ascii')).digest()).decode().rstrip('=')
                if (not item or not item['authorized'] or item['deadline'] <= time.time()
                        or item['code'] != data['code'] or challenge != item['challenge']):
                    return self.reply(401)
                credential = secrets.token_urlsafe(32)
                self.server.sessions[credential] = int(time.time()) + 300
                return self.reply(200, dict(access_token=credential, token_type='Bearer',
                    sub='00000000-0000-4000-8000-000000000001', expires_at=int(time.time()) + 300))
            credential = self.headers.get('Authorization', '').removeprefix('Bearer ')
            deadline = self.server.sessions.get(credential)
            if deadline is None or deadline <= time.time():
                self.server.sessions.pop(credential, None)
                return self.reply(401)
            if kind == 'session':
                return self.reply(200, dict(sub='00000000-0000-4000-8000-000000000001', app_id='life_diary'))
            self.server.sessions.pop(credential, None)
            return self.reply(204)
        except (ValueError, TypeError, KeyError, UnicodeError):
            return self.reply(422)


if __name__ == '__main__':
    try:
        server = Fixture()
    except OSError:
        raise SystemExit('CONFLICT: cannot bind 127.0.0.1:8000; existing process left untouched')
    print('Synthetic fixture listening on 127.0.0.1:8000', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        print(json.dumps(server.counts), flush=True)
