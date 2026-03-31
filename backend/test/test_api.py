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
            {'id': 1, 'part_number': 'RC0402FR-0710KL', 'manufacturer': 'Yageo', 'category': 'res'},
            {'id': 2, 'part_number': 'GRM155R71C104K', 'manufacturer': 'Murata', 'category': 'cap'},
        ],
        fetchrow_row={
            'id': 1, 'part_number': 'RC0402FR-0710KL', 'manufacturer': 'Yageo',
            'category': 'res', 'attributes': '{"resistance": "10k"}',
        },
    )


@pytest.fixture
def mock_gemini_client():
    mock_client = AsyncMock()
    mock_response = AsyncMock()
    mock_response.text = '{"components": [], "connections": []}'
    mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)
    return mock_client


@pytest.fixture
def app(mock_pool, mock_gemini_client):
    with patch('main.get_pool', new_callable=AsyncMock, return_value=mock_pool):
        with patch('gemini_service._client', mock_gemini_client):
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
    data = response.json()
    assert 'status' in data
    assert 'database' in data


def test_categories(client):
    response = client.get('/categories')
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_search_empty_query(client):
    response = client.get('/search?q=')
    assert response.status_code == 400


def test_search_success(client):
    response = client.get('/search?q=resistor')
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


def test_search_with_category(client):
    response = client.get('/search?q=RC0402&category=res')
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_get_component_success(client):
    response = client.get('/component/1')
    assert response.status_code == 200
    data = response.json()
    assert data['part_number'] == 'RC0402FR-0710KL'
    assert data['manufacturer'] == 'Yageo'


def test_get_component_not_found(client):
    empty_pool = make_mock_pool(fetchrow_row=None)
    with patch('main.get_pool', new_callable=AsyncMock, return_value=empty_pool):
        response = client.get('/component/999')
        assert response.status_code == 404


def test_suggestions_empty_query(client):
    response = client.get('/suggestions?q=')
    assert response.status_code == 200
    assert response.json() == []


def test_suggestions_success(client):
    response = client.get('/suggestions?q=resistor')
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_generate_circuit_empty_query(client):
    response = client.post('/generate_circuit', json={'query': '', 'inventory': []})
    assert response.status_code in (400, 422)


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

    async def async_mock(*args, **kwargs):
        return mock_response

    with patch('main.generate_circuit', new_callable=AsyncMock, side_effect=async_mock):
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
    async def async_error(*args, **kwargs):
        raise ValueError('Invalid response')

    with patch('main.generate_circuit', new_callable=AsyncMock, side_effect=async_error):
        response = client.post(
            '/generate_circuit',
            json={'query': 'LED blinker circuit', 'inventory': []},
        )
        assert response.status_code == 502
