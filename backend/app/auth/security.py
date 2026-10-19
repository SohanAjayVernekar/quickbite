from datetime import timedelta
import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError, InvalidHashError
from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import select
from app.config.settings import settings
from app.database.session import Session
from app.models.entities import User, utcnow, uid
from app.api.errors import ApiError

hasher=PasswordHasher()
bearer=HTTPBearer(auto_error=False)
DUMMY_HASH=hasher.hash('not-a-real-account-password')

def profile(user): return {'id':user.id,'email':user.email,'name':user.name,'role':user.role}
def verify(password,hashed):
    try: return hasher.verify(hashed,password)
    except (VerificationError,InvalidHashError): return False

def issue_token(user):
    cfg=settings(); now=utcnow(); expiry=now+timedelta(minutes=cfg.jwt_minutes)
    claims={'sub':user.id,'role':user.role,'iss':cfg.jwt_issuer,'aud':cfg.jwt_audience,
            'iat':now,'exp':expiry,'jti':uid()}
    return {'access_token':jwt.encode(claims,cfg.jwt_secret,algorithm='HS256'),
            'token_type':'bearer','expires_at':expiry.isoformat(),'expires_in':cfg.jwt_minutes*60,
            'role':user.role,'user':profile(user)}

async def current_user(credentials:HTTPAuthorizationCredentials|None=Depends(bearer)):
    try:
        if not credentials: raise ValueError()
        cfg=settings()
        claims=jwt.decode(credentials.credentials,cfg.jwt_secret,algorithms=['HS256'],
            issuer=cfg.jwt_issuer,audience=cfg.jwt_audience,
            options={'require':['sub','exp','iat','iss','aud','jti','role']})
        if not isinstance(claims['sub'],str): raise ValueError()
        async with Session() as s: user=await s.get(User,claims['sub'])
        if not user or not user.active or user.role!=claims['role']: raise ValueError()
        return user
    except (jwt.PyJWTError,ValueError,KeyError):
        raise ApiError(401,'AUTHENTICATION_REQUIRED','Please sign in again.') from None

def role_required(role):
    async def dependency(user:User=Depends(current_user)):
        if user.role!=role: raise ApiError(403,'FORBIDDEN','This action is not available to your role.')
        return user
    return dependency
customer=role_required('CUSTOMER')
admin=role_required('ADMIN')
