from fastapi import FastAPI, Request
import httpx
import os
import psycopg2
from audit import audit_log

GO_SERVICE_URL = os.getenv("GO_SERVICE_URL")

app = FastAPI()

@app.get("/ping")
def ping():
    return {"message": "Python backend up"}

@app.get("/go-data")
def call_go():
    r = httpx.get(f"{GO_SERVICE_URL}/internal")
    return {"go_response": r.json()}

@app.middleware("http")
async def audit_middleware(request: Request, call_next):
    response = await call_next(request)

    audit_log(
        action="http_request",
        entity="route",
        entity_id=str(request.url.path),
        user_id=request.headers.get("X-User-ID"),
        request_ip=request.client.host,
        details={"method": request.method, "status": response.status_code}
    )

    return response