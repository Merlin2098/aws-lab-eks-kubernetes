from fastapi import FastAPI

APP_VERSION = "1.0"

app = FastAPI(title="invoice-processor")


@app.get("/")
def root() -> dict:
    return {
        "service": "invoice-processor",
        "version": APP_VERSION,
        "status": "healthy",
    }


@app.get("/version")
def version() -> dict:
    return {"version": APP_VERSION}


@app.get("/health")
def health() -> dict:
    return {"status": "healthy"}
