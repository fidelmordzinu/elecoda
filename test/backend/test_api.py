import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'backend')))


@pytest.fixture
def mock_pool():
    pool = AsyncMock()
    conn = AsyncMock()
    conn.fetch = AsyncMock(return_value=[
        {'id': 1, 'mpn': 'RC0402FR-0710KL', 'description': 'Resistor 10k 0402', 'category': 'resistor'},
        {'id': 2, 'mpn': 'GRM155R71C104K', 'description': 'Capacitor 100nF 0402', 'category': 'capacitor'},
    ])
    conn.fetchrow = AsyncMock(return_value={
        'id': 1, 'mpn': 'RC0402FR-0710KL', 'description': 'Resistor 10k 0402',
        'datasheet_url': 'https://example.com/datasheet', 'specs': '{"resistance": "10k"}',
        'category': 'resistor',
    })
    acquire_ctx = AsyncMock()
    acquire_ctx.__aenter__ = AsyncMock(return_value=conn)
    acquire_ctx.__aexit__ = AsyncMock(return_value=None)
    pool.acquire.return_value = acquire_ctx
    return pool


@pytest.fixture
def app(mock_pool):
    with patch('backend.database._pool', mock_pool):
        with patch('backend.database.get_pool', return_value=mock_pool):
            from backend.main import app
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
    with patch('backend.main.get_pool') as mock_get_pool:
        mock_pool = AsyncMock()
        mock_conn = AsyncMock()
        mock_conn.fetchrow = AsyncMock(return_value=None)
        mock_acquire = AsyncMock()
        mock_acquire.__aenter__ = AsyncMock(return_value=mock_conn)
        mock_acquire.__aexit__ = AsyncMock(return_value=None)
        mock_pool.acquire.return_value = mock_acquire
        mock_get_pool.return_value = mock_pool

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

    with patch('backend.main.generate_circuit', return_value=mock_response):
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
    with patch('backend.main.generate_circuit', side_effect=ValueError('Invalid response')):
        response = client.post(
            '/generate_circuit',
            json={'query': 'LED blinker circuit', 'inventory': []},
        )
        assert response.status_code == 502
