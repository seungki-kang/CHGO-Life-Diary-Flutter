"""Bounded loopback regression tests; never connect to the port-8000 fixture."""
import base64
import hashlib
import http.client
import json
import re
import socket
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlsplit

from fake_life_diary_auth import BINDING, PREFIX, Fixture, Handler


class FixtureTests(unittest.TestCase):
    def setUp(self):
        self.accepted = threading.Event()
        self.reading = threading.Event()
        accepted, reading = self.accepted, self.reading

        class ProbeHandler(Handler):
            def setup(self):
                super().setup()
                accepted.set()

            def dispatch(self):
                reading.set()
                return super().dispatch()

        self.server = Fixture(('127.0.0.1', 0))
        self.server.RequestHandlerClass = ProbeHandler
        self.thread = threading.Thread(target=self.server.serve_forever,
                                       kwargs={'poll_interval': 0.02}, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)
        self.assertFalse(self.thread.is_alive())

    def request(self, path, body=None, credential=None):
        connection = http.client.HTTPConnection(*self.server.server_address, timeout=1)
        headers = {'Content-Type': 'application/json'}
        if credential:
            headers['Authorization'] = 'Bearer ' + credential
        try:
            connection.request('GET' if body is None else 'POST', path,
                               None if body is None else json.dumps(body), headers)
            response = connection.getresponse()
            payload = response.read()
            return response.status, payload
        finally:
            connection.close()

    def assert_stats_with_open_connection(self, wire, wait_for_body=False):
        with socket.create_connection(self.server.server_address, timeout=1) as held:
            if wire:
                held.sendall(wire)
            self.assertTrue(self.accepted.wait(1), 'connection was not accepted')
            if wait_for_body:
                self.assertTrue(self.reading.wait(1), 'handler did not reach body read')
            # Request must complete while held is still open, before its 5s timeout.
            status, payload = self.request('/__synthetic_stats')
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(payload)['upload'], 0)

    def test_idle_browser_connection(self):
        self.assert_stats_with_open_connection(b'')

    def test_partial_headers(self):
        self.assert_stats_with_open_connection(b'GET / HTTP/1.1\r\nHost: localhost\r\n')

    def test_partial_body_does_not_hold_state_lock(self):
        self.assert_stats_with_open_connection(
            b'POST ' + PREFIX.encode() + b'/session-exchange HTTP/1.0\r\n'
            b'Content-Length: 100\r\n\r\n{', wait_for_body=True)

    def authorize(self, verifier):
        challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).decode().rstrip('=')
        status, payload = self.request(PREFIX + '/login-transactions', dict(BINDING, challenge=challenge))
        self.assertEqual(status, 200)
        transaction = json.loads(payload)
        url = urlsplit(transaction['authorize_url'])
        self.assertEqual(url.port, 8000)
        status, page = self.request(url.path + '?' + url.query)
        self.assertEqual(status, 200)
        self.assertEqual(self.request(url.path + '?' + url.query)[0], 401)
        code = re.search(rb'code=([A-Za-z0-9_-]{43})', page).group(1).decode()
        return dict(BINDING, transaction=transaction['transaction'], code=code, verifier=verifier)

    def test_pkce_replay_session_logout(self):
        body = self.authorize('v' * 43)
        status, _ = self.request(PREFIX + '/session-exchange', dict(body, verifier='x' * 43))
        self.assertEqual(status, 401)
        self.assertEqual(self.request(PREFIX + '/session-exchange', body)[0], 401)
        body = self.authorize('v' * 43)
        status, payload = self.request(PREFIX + '/session-exchange', body)
        self.assertEqual(status, 200)
        token = json.loads(payload)['access_token']
        self.assertEqual(self.request(PREFIX + '/session-exchange', body)[0], 401)
        self.assertEqual(self.request(PREFIX + '/session', credential=token)[0], 200)
        self.assertEqual(self.request(PREFIX + '/logout', {}, token)[0], 204)
        self.assertEqual(self.request(PREFIX + '/session', credential=token)[0], 401)


    def test_expired_session_is_rejected_and_removed(self):
        body = self.authorize('v' * 43)
        status, payload = self.request(PREFIX + '/session-exchange', body)
        self.assertEqual(status, 200)
        token = json.loads(payload)['access_token']
        self.assertEqual(self.request(PREFIX + '/session', credential=token)[0], 200)

        # Expire only this synthetic session without sleeping.
        with self.server.state_lock:
            self.server.sessions[token] = 0

        self.assertEqual(self.request(PREFIX + '/session', credential=token)[0], 401)
        with self.server.state_lock:
            self.assertNotIn(token, self.server.sessions)
        self.assertEqual(self.request(PREFIX + '/logout', {}, token)[0], 401)

    def test_non_object_json_is_rejected(self):
        for route in ('/login-transactions', '/session-exchange'):
            for value in (None, [], ['unexpected'], 'text', 123, True):
                with self.subTest(route=route, value=value):
                    connection = http.client.HTTPConnection(
                        *self.server.server_address, timeout=1)
                    try:
                        connection.request(
                            'POST', PREFIX + route,
                            json.dumps(value),
                            {'Content-Type': 'application/json'})
                        response = connection.getresponse()
                        self.assertEqual(response.status, 422)
                        response.read()
                    finally:
                        connection.close()
        self.assertEqual(self.request('/__synthetic_stats')[0], 200)

    def test_concurrent_exchange_is_one_time(self):
        body = self.authorize('v' * 43)
        barrier = threading.Barrier(2, timeout=2)

        def exchange():
            barrier.wait()
            return self.request(PREFIX + '/session-exchange', body)[0]

        with ThreadPoolExecutor(max_workers=2) as pool:
            futures = [pool.submit(exchange) for _ in range(2)]
            self.assertEqual(sorted(f.result(timeout=3) for f in futures), [200, 401])


if __name__ == '__main__':
    unittest.main()
