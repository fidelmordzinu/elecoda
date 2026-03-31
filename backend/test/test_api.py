import pytest
from unittest.mock import AsyncMock, patch
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))


class AsyncContextManagerMock:
    def __init__(self, return_value):
        self.return_value = return_value

    async def __aenter__(self):
        return self.return_value

    async def __aexit__(self, exc_type, exc, tb):
        pass


def make_mock_pool(fetch_rows=None, fetchrow_row=None):
    conn = AsyncMock()
    if fetch_rows is not None:
        conn.fetch = AsyncMock(return_value=fetch_rows)
    conn.fetchrow = AsyncMock(return_value=fetchrow_row)

    pool = AsyncMock()
    pool.acquire = lambda: AsyncContextManagerMock(conn)
    return pool


@pytest.fixture
def mock_pool():
    return make_mock_pool(
        fetch_rows=[
            {'id': 1, 'mpn': 'RC0402FR-0710KL', 'description': 'Resistor 10k 0402', 'category': 'resistor'},
            {'id': 2, 'mpn': 'GRM155R71C104K', 'description': 'Capacitor 100nF 0402', 'category': 'capacitor'},
        ],
        fetchrow_row={
            'id': 1, 'mpn': 'RC0402FR-0710KL', 'description': 'Resistor 10k 0402',
            'datasheet_url': 'https://example.com/datasheet', 'specs': '{"resistance": "10k"}',
            'category': 'resistor',
        },
    )


@pytest.fixture
def app(mock_pool):
    with patch('main.get_pool', new_callable=AsyncMock, return_value=mock_pool):
        from main import app
        yield app


@pytest.fixture
def client(app):
    from fastapi.testclient import TestClient
    return TestClient(app)


def test_root(client):
    response = client.get('/')
    assert response.status_code == 200
    assert 'message' in response.json()


def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'healthy'


def test_search_empty_query(client):
    response = client.get('/search?q=')
    assert response.status_code == 400


def test_search_success(client):
    response = client.get('/search?q=resistor')
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


def test_get_component_success(client):
    response = client.get('/component/1')
    assert response.status_code == 200
    data = response.json()
    assert data['mpn'] == 'RC0402FR-0710KL'


def test_get_component_not_found(client):
    empty_pool = make_mock_pool(fetchrow_row=None)
    with patch('main.get_pool', new_callable=AsyncMock, return_value=empty_pool):
        response = client.get('/component/999')
        assert response.status_code == 404


def test_generate_circuit_empty_query(client):
    response = client.post('/generate_circuit', json={'query': '', 'inventory': []})
    assert response.status_code == 400


def test_generate_circuit_success(client):
    mock_response = {
        'components': [
            {'ref': 'R1', 'type': 'resistor', 'value': '10k', 'mpn': 'RC0402FR-0710KL', 'in_inventory': False},
            {'ref': 'C1', 'type': 'capacitor', 'value': '100nF', 'mpn': None, 'in_inventory': True},
        ],
        'connections': [
            {'from': 'R1.pin1', 'to': 'C1.pin1'},
        ],
    }

    with patch('main.generate_circuit', return_value=mock_response):
        response = client.post(
            '/generate_circuit',
            json={'query': 'LED blinker circuit', 'inventory': ['GRM155R71C104K']},
        )
        assert response.status_code == 200
        data = response.json()
        assert 'components' in data
        assert 'connections' in data
        assert len(data['components']) == 2


def test_generate_circuit_gemini_error(client):
    with patch('main.generate_circuit', side_effect=ValueError('Invalid response')):
        response = client.post(
            '/generate_circuit',
            json={'query': 'LED blinker circuit', 'inventory': []},
        )
        assert response.status_code == 502
