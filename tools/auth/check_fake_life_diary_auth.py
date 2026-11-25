"""Check an explicitly running loopback fixture; never follow redirects."""
import base64
import hashlib
import json
import re
from urllib.request import Request, build_opener, HTTPRedirectHandler, ProxyHandler
from urllib.error import HTTPError
from urllib.parse import urlsplit, parse_qs

from fake_life_diary_auth import BINDING, PREFIX

BASE = 'http://127.0.0.1:8000'
MARKER = 'life-diary-synthetic-v1'


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


opener = build_opener(ProxyHandler({}), NoRedirect())


def fetch(url, body=None, credential=None):
    headers = {'Content-Type': 'application/json'}
    if credential:
        headers['Authorization'] = 'Bearer ' + credential
    request = Request(
        url, data=None if body is None else json.dumps(body).encode(),
        headers=headers)
    with opener.open(request, timeout=5) as response:
        raw = response.read(65537)
        if len(raw) > 65536:
            raise ValueError('Response too large')
        return raw


def request(path, body=None, credential=None):
    raw = fetch(BASE + path, body, credential)
    return json.loads(raw) if raw else None


def authorize_url(value):
    if not isinstance(value, str):
        raise ValueError('Invalid fixture URL')
    url = urlsplit(value)
    query = parse_qs(url.query, keep_blank_values=True)
    if (
        url.scheme != 'http' or url.netloc != '127.0.0.1:8000'
        or url.path != PREFIX + '/authorize' or url.fragment
        or set(query) != {'state'} or len(query['state']) != 1
        or not re.fullmatch(r'[A-Za-z0-9_-]{43}', query['state'][0])
    ):
        raise ValueError('Invalid fixture URL')
    return value


def main():
    stats = request('/__synthetic_stats')
    if not isinstance(stats, dict) or stats.get('fixture') != MARKER:
        raise ValueError('Synthetic fixture not confirmed')

    verifier = 'v' * 43
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode()).digest()).decode().rstrip('=')
    start = request(PREFIX + '/login-transactions', dict(BINDING, challenge=challenge))
    page = fetch(authorize_url(start['authorize_url'])).decode()
    match = re.search(r'code=([A-Za-z0-9_-]{43})(?![A-Za-z0-9_-])', page)
    if match is None:
        raise ValueError('Invalid synthetic callback')
    body = dict(BINDING, transaction=start['transaction'],
                code=match.group(1), verifier=verifier)
    session = request(PREFIX + '/session-exchange', body)
    if request(PREFIX + '/session', credential=session['access_token'])['sub'] != session['sub']:
        raise ValueError('Session mismatch')
    try:
        request(PREFIX + '/session-exchange', body)
    except HTTPError as error:
        if error.code != 401:
            raise ValueError('Unexpected replay status') from None
    else:
        raise ValueError('Replay accepted')
    request(PREFIX + '/logout', {}, session['access_token'])
    stats = request('/__synthetic_stats')
    if stats.get('fixture') != MARKER or stats.get('upload') != 0:
        raise ValueError('Unexpected fixture counters')
    keys = ('start', 'authorize', 'exchange', 'session', 'logout', 'upload')
    counters = {key: stats[key] for key in keys}
    if any(type(value) is not int or value < 0 for value in counters.values()):
        raise ValueError('Invalid counters')
    print('PASS synthetic HTTP/PKCE/session/logout/replay; counters:', counters)


if __name__ == '__main__':
    try:
        main()
    except Exception:
        raise SystemExit('FAIL: synthetic fixture check; details suppressed') from None
