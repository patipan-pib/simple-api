import unittest
from app.app import app  # Adjust import based on your structure

class AppTestCase(unittest.TestCase):
    def setUp(self):
        # Initialize the Flask test client
        self.app = app.test_client()
        self.app.testing = True

    # def test_getcode(self):
    #     # Test the /getcode endpoint
    #     res = self.app.get('/getcode')
    #     self.assertEqual(res.get_json(), {"code": "success"})

    def test_plus_ok(self):
        # Test the /plus/5/7 endpoint
        res = self.app.get('/plus/5/7')
        self.assertEqual(res.json, {'result': 12})

if __name__ == "__main__":
    unittest.main()