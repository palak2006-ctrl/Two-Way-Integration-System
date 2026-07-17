from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from app.api import customers, webhooks
from app.database import engine, Base

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Zenskar Integration API",
    description="Two-way customer sync with external systems",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(customers.router)
app.include_router(webhooks.router)


@app.get("/")
def root():
    return {
        "message": "Zenskar Integration API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
