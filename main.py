from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from google.cloud import pubsub_v1
import json

app = FastAPI()
publisher = pubsub_v1.PublisherClient()

topic_path = publisher.topic_path(
    "whereami-500117",
    "whereami-locations"
)

#CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/")
async def receive(request: Request):
    data = await request.json()

    info = {
        "user": data.get("topic", "").split("/")[-1],
        "acc": data.get("acc"),
        "vac": data.get("vac"),
        "lat": data.get("lat"),
        "lon": data.get("lon"),
        "alt": data.get("alt"),
        "vel": data.get("vel"),
        "tst": data.get("tst"),
        "cog": data.get("cog")
    }

    print(info)

    future = publisher.publish(
        topic_path,
        json.dumps(info).encode("utf-8")
    )

    message_id = future.result()

    return {"message_id": message_id}