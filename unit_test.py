import unittest

from app import app

class AppTestCase(unittest.TestCase):

    def test_getcode(self):
        # test hello
        res = app.getcode()
        self.assertEqual(res)

    def test_plus_ok(self):
        res = app.plus(5, 7)
        self.assertEqual(res.json, { 'result': 12 })

if __name__ == "__main__":
    unittest.main()
