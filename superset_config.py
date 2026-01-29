# BTRC QoS Monitoring - Apache Superset Configuration
import os
from datetime import timedelta

# Secret key for Superset
SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'btrc-qos-monitoring-secret-key-2026')

# Database connection for Superset metadata
SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'postgresql://superset:superset@superset-db:5432/superset')

# Redis configuration
REDIS_HOST = os.environ.get('REDIS_HOST', 'redis')
REDIS_PORT = os.environ.get('REDIS_PORT', 6379)
REDIS_CELERY_DB = os.environ.get('REDIS_CELERY_DB', 0)
REDIS_RESULTS_DB = os.environ.get('REDIS_RESULTS_DB', 1)

# Cache configuration
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_HOST': REDIS_HOST,
    'CACHE_REDIS_PORT': REDIS_PORT,
    'CACHE_REDIS_DB': REDIS_RESULTS_DB,
}

DATA_CACHE_CONFIG = CACHE_CONFIG

# Celery configuration for async queries
class CeleryConfig:
    broker_url = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_CELERY_DB}'
    result_backend = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_RESULTS_DB}'
    task_always_eager = False
    task_acks_late = True

CELERY_CONFIG = CeleryConfig

# Feature flags
FEATURE_FLAGS = {
    "DASHBOARD_NATIVE_FILTERS": True,
    "DASHBOARD_CROSS_FILTERS": True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "EMBEDDABLE_CHARTS": True,
    "EMBEDDED_SUPERSET": True,
    "ALERT_REPORTS": True,
}

# BTRC Custom Color Scheme
EXTRA_CATEGORICAL_COLOR_SCHEMES = [
    {
        "id": "btrcColors",
        "description": "BTRC Brand Colors",
        "label": "BTRC Colors",
        "isDefault": True,
        "colors": [
            "#00a651",  # BTRC Green
            "#0066b3",  # Government Blue
            "#52c41a",  # Success
            "#faad14",  # Warning
            "#ff4d4f",  # Error
            "#1890ff",  # Info
            "#722ed1",  # Purple
            "#eb2f96",  # Pink
        ]
    }
]

EXTRA_SEQUENTIAL_COLOR_SCHEMES = [
    {
        "id": "btrcStatus",
        "description": "BTRC Status Colors",
        "label": "Status",
        "colors": [
            "#ff4d4f",  # Down/Critical
            "#faad14",  # Degraded/Warning
            "#52c41a",  # Healthy/Good
        ]
    }
]

# Timezone settings
BABEL_DEFAULT_LOCALE = "en"
BABEL_DEFAULT_FOLDER = "superset/translations"

# Web server settings
SUPERSET_WEBSERVER_TIMEOUT = 300
SUPERSET_WEBSERVER_PORT = 8088

# SQL Lab settings
SQLLAB_TIMEOUT = 300
SQLLAB_ASYNC_TIME_LIMIT_SEC = 600

# Row limit for queries
ROW_LIMIT = 50000
SQL_MAX_ROW = 100000

# Enable SQL Lab
ENABLE_PROXY_FIX = True

# Security settings
WTF_CSRF_ENABLED = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = False  # Set to True in production with HTTPS
SESSION_COOKIE_SAMESITE = "Lax"

# Logging
LOG_FORMAT = "%(asctime)s:%(levelname)s:%(name)s:%(message)s"
LOG_LEVEL = "INFO"

# Allow embedding
HTTP_HEADERS = {}
TALISMAN_ENABLED = False  # Disable for development; enable in production

# Public role settings (for embedding)
PUBLIC_ROLE_LIKE = "Gamma"
