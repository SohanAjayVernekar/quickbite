from datetime import datetime
from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator, AwareDatetime

class StrictModel(BaseModel):
    model_config = ConfigDict(extra='forbid')
class Login(StrictModel):
    email: str = Field(min_length=3,max_length=254)
    password: str = Field(min_length=1,max_length=200)
class ItemInput(StrictModel):
    menu_item_id: str = Field(min_length=1,max_length=64)
    quantity: int = Field(ge=1,le=20,strict=True)
class Checkout(StrictModel):
    restaurant_id: str = Field(min_length=1,max_length=64)
    delivery_address: str = Field(min_length=10,max_length=500)
    items: list[ItemInput] = Field(min_length=1,max_length=20)
    @field_validator('delivery_address')
    @classmethod
    def clean_address(cls,v):
        v=' '.join(v.split())
        if len(v)<10 or not any(c.isalpha() for c in v) or any(ord(c)<32 for c in v):
            raise ValueError('Enter a complete delivery address, at least 10 characters.')
        return v
    @model_validator(mode='after')
    def distinct(self):
        if len({i.menu_item_id for i in self.items})!=len(self.items):
            raise ValueError('Each menu item may appear only once')
        return self

class RestaurantCreate(StrictModel):
    name: str = Field(min_length=2, max_length=120)
    cuisine: str = Field(min_length=2, max_length=80)
    description: str = Field(min_length=5, max_length=1000)
    image: str = Field(default='', max_length=200)
    available: bool = True
    eta_minutes: int = Field(default=30, ge=5, le=240, strict=True)

    @field_validator('name', 'cuisine', 'description', 'image')
    @classmethod
    def tidy_catalog_text(cls, value):
        value = ' '.join(value.split())
        if '\x00' in value:
            raise ValueError('Text contains an unsupported character.')
        return value

class DishCreate(StrictModel):
    name: str = Field(min_length=2, max_length=120)
    description: str = Field(min_length=5, max_length=1000)
    image: str = Field(default='', max_length=200)
    price_minor: int = Field(ge=0, le=10_000_000, strict=True)
    currency: str = Field(default='INR', min_length=3, max_length=3)
    vegetarian: bool = True
    available: bool = True

    @field_validator('name', 'description', 'image')
    @classmethod
    def tidy_dish_text(cls, value):
        value = ' '.join(value.split())
        if '\x00' in value:
            raise ValueError('Text contains an unsupported character.')
        return value

class AvailabilityUpdate(StrictModel):
    available: bool

class Event(StrictModel):
    event_id: str = Field(pattern=r'^[a-zA-Z0-9_-]{1,64}$')
    schema_version: Literal[1]
    event_type: str = Field(pattern=r'^order\.[a-z]+(?:\.[a-z]+)*$',max_length=100)
    order_id: str = Field(min_length=1,max_length=64)
    order_version: int = Field(ge=1,strict=True)
    occurred_at: AwareDatetime
    correlation_id: str = Field(min_length=1,max_length=64)
    causation_id: str | None = Field(max_length=64)
    data: dict
