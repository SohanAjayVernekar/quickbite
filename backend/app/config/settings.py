from functools import lru_cache
from typing import Literal
from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env', extra='ignore')
    app_env: Literal['development', 'test', 'production'] = 'development'
    database_url: str
    amqp_url: str
    jwt_secret: str = Field(min_length=32)
    jwt_issuer: str = 'quickbite'
    jwt_audience: str = 'quickbite-client'
    jwt_minutes: int = Field(default=30, ge=1, le=120)
    cors_origins: str = 'http://localhost:8080,http://127.0.0.1:8080'
    rabbitmq_management_url: str = 'http://rabbitmq:15672'
    rabbitmq_user: str = 'quickbite'
    rabbitmq_password: str
    retry_delays: str = '2,10,30'
    payment_delay_ms: int = Field(default=500, ge=0, le=10000)
    restaurant_delay_ms: int = Field(default=150, ge=0, le=10000)
    delivery_delay_ms: int = Field(default=150, ge=0, le=10000)
    notification_delay_ms: int = Field(default=20, ge=0, le=10000)
    prefetch: int = Field(default=8, ge=1, le=100)
    enable_demo_failures: bool = False
    demo_mode: Literal['success','payment_fail_twice','payment_always_fail','payment_decline',
                       'restaurant_terminal','delivery_terminal','notification_fail'] = 'success'
    crash_checkpoint: Literal['none','before_commit','after_commit_before_ack','publish_before_mark'] = 'none'
    crash_service: str = 'payment'
    @model_validator(mode='after')
    def validate_config(self):
        if not self.database_url.startswith('postgresql+asyncpg://'):
            raise ValueError('DATABASE_URL must use postgresql+asyncpg')
        if not self.amqp_url.startswith(('amqp://','amqps://')):
            raise ValueError('AMQP_URL must use AMQP')
        if '*' in self.origins:
            raise ValueError('CORS origins must be explicit')
        if len(self.delays) != 3 or any(d <= 0 for d in self.delays):
            raise ValueError('RETRY_DELAYS must contain three positive seconds')
        if self.app_env == 'production' and (self.enable_demo_failures or self.demo_mode != 'success' or self.crash_checkpoint != 'none'):
            raise ValueError('Failure injection is forbidden in production')
        return self
    @property
    def delays(self): return [float(x) for x in self.retry_delays.split(',')]
    @property
    def origins(self): return [x.strip() for x in self.cors_origins.split(',') if x.strip()]

@lru_cache
def settings(): return Settings()
