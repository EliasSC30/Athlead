const WebSocket = require("ws");

const ws = new WebSocket("ws://localhost:8000/ws/b5855ba6-c114-4817-93a3-7bca520f1b11");


ws.on("open", () => {
    console.log("Connected to WebSocket server");
    ws.send("Hello from Node.js!");
});

ws.on("message", (message) => {
    console.log("Message from server:", message);
});

ws.on("close", (code, reason) => {
    console.log(`WebSocket closed: code=${code}, reason=${reason}`);
});

ws.on("error", (error) => {
    console.error("WebSocket error:", error);
});

