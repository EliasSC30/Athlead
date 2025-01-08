const WebSocket = require("ws");


const cookies = "Token=hnpcagapjjbnpkngieabdbmhmigijcapfdofoifggilonmlcfmgmjjbldikokigefbchmhpbbcifehhegipnpbackobhcfigpkjlagppahimpjiogelcaodpllbdoffiieecbaaa;";

const socket = new WebSocket("ws://localhost:8000/ws/b5855ba6-c114-4817-93a3-7bca520f1b11", {
    headers: {
        Cookie: cookies
    }
});



socket.on("open", () => {
    console.log("Connected to WebSocket server");
});

socket.on("message",(msg)=>{
    console.log("Received a message :) : ", msg)
});

socket.on('pong', () => {
    console.log("Pong received from server.");
});

socket.addEventListener('close', (event) => {
    console.log("WebSocket closed:", event.code, event.reason);
});

