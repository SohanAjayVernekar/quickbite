from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException
from app.config.logging import log

class ApiError(Exception):
    def __init__(self,status,code,message,details=None):
        self.status,self.code,self.message,self.details=status,code,message,details or {}

def body(request,code,message,details=None):
    return {'code':code,'message':message,'details':details or {},'request_id':getattr(request.state,'request_id','unknown')}

def register_errors(app):
    @app.exception_handler(ApiError)
    async def domain_error(request:Request,e:ApiError):
        return JSONResponse(body(request,e.code,e.message,e.details),status_code=e.status,
                            headers={'WWW-Authenticate':'Bearer'} if e.status==401 else None)
    @app.exception_handler(RequestValidationError)
    async def validation(request:Request,e:RequestValidationError):
        # Never include the rejected input: it may contain a password or address.
        issues=[{'field':'.'.join(str(x) for x in err['loc']),'message':err['msg']} for err in e.errors()]
        return JSONResponse(body(request,'INVALID_INPUT','Please check the supplied information.',{'issues':issues}),status_code=422)
    @app.exception_handler(HTTPException)
    async def http_error(request:Request,e:HTTPException):
        return JSONResponse(body(request,f'HTTP_{e.status_code}',str(e.detail)),status_code=e.status_code)
    @app.exception_handler(Exception)
    async def internal(request:Request,e:Exception):
        log('api','error',request_id=getattr(request.state,'request_id',None),error_type=type(e).__name__)
        return JSONResponse(body(request,'SERVICE_UNAVAILABLE','The request could not finish. Retry safely using the same checkout key.'),status_code=503)
