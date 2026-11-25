import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest.mock import patch
from urllib.error import HTTPError

import check_fake_life_diary_auth as check


class CheckerTests(unittest.TestCase):
    def test_import_does_not_connect(self):
        # Import above must not execute main or contact port 8000.
        self.assertTrue(callable(check.main))

    def test_unconfirmed_server_stops_before_authentication(self):
        for result in ({}, {'fixture': 'other'}, None):
            with self.subTest(result=result):
                with patch.object(check, 'request', return_value=result) as request:
                    with patch.object(check, 'fetch') as fetch:
                        with self.assertRaises(ValueError):
                            check.main()
                        request.assert_called_once_with('/__synthetic_stats')
                        fetch.assert_not_called()

    def test_authorize_url_allowlist(self):
        good = check.BASE + check.PREFIX + '/authorize?state=' + 'a' * 43
        self.assertEqual(check.authorize_url(good), good)
        invalid = [
            None,
            good.replace('127.0.0.1', 'example.com'),
            good.replace('http:', 'https:'),
            good.replace(':8000', ':8001'),
            good.replace('127.0.0.1', 'user@127.0.0.1'),
            good + '#fragment',
            good + '&extra=1',
            good + '&state=' + 'b' * 43,
            good[:-1],
            good.replace('/authorize?', '/session?'),
        ]
        for value in invalid:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    check.authorize_url(value)

    def test_redirect_is_not_followed(self):
        hits = []

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_):
                pass

            def do_GET(self):
                hits.append(self.path)
                self.send_response(302)
                self.send_header('Location', '/target')
                self.send_header('Content-Length', '0')
                self.end_headers()

        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(
            target=server.serve_forever,
            kwargs={'poll_interval': 0.02}, daemon=True)
        thread.start()
        try:
            host, port = server.server_address
            with self.assertRaises(HTTPError) as caught:
                check.fetch(f'http://{host}:{port}/redirect')
            self.assertEqual(caught.exception.code, 302)
            self.assertEqual(hits, ['/redirect'])
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)
            self.assertFalse(thread.is_alive())


if __name__ == '__main__':
    unittest.main()
