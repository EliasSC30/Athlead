use std::collections::{HashMap, HashSet};
use actix::{fut, ActorContext, ActorFutureExt, AsyncContext, Context};
use actix_web_actors::ws;
use actix::{Actor, Addr, ContextFutureSpawner, Running, StreamHandler, WrapFuture};
use actix::{Handler};
use std::time::{Duration, Instant};
use uuid::Uuid;
use actix::prelude::{Message,Recipient};
use actix_web::{get, HttpRequest, HttpResponse, Responder};
use actix_web::web::{Data, Path, Payload};
use actix_web_actors::ws::ProtocolError;
use serde_json::json;

#[derive(Message)]
#[rtype(result = "()")]
pub struct WsMessage(pub String);
#[derive(Message)]
#[rtype(result = "()")]
pub struct Connect{
    pub addr: Recipient<WsMessage>,
    pub lobby_id: Uuid,
    pub self_id: Uuid,
}

#[derive(Message)]
#[rtype(result = "()")]
pub struct Disconnect {
    pub id: Uuid,
    pub room_id: Uuid,
}

#[derive(Message)]
#[rtype(result = "()")]
pub struct ClientActorMessage {
    pub id: Uuid,
    pub msg: String,
    pub room_id: Uuid,
}

type Socket = Recipient<WsMessage>;
pub struct Lobby {
    pub sessions: HashMap<Uuid, Socket>,
    pub rooms: HashMap<Uuid, HashSet<Uuid>>,
}

impl Default for Lobby {
    fn default() -> Lobby {
        Lobby {
            sessions: HashMap::new(),
            rooms: HashMap::new(),
        }
    }
}

impl Lobby {
    pub fn send_message(&self, message: &str, id_to: &Uuid) {
        if let Some(socket_recipient) = self.sessions.get(id_to) {
            let _ = socket_recipient.do_send(WsMessage(message.to_owned()));
        } else {
            println!("Could not find socket recipient");
        }
    }
}

impl Actor for Lobby {
    type Context = Context<Self>;
}

impl Handler<Disconnect> for Lobby {
    type Result = ();
    fn handle(&mut self, msg: Disconnect, _: &mut Self::Context) -> () {
        if self.sessions.remove(&msg.id).is_some() {
            self.rooms.get(&msg.room_id).unwrap()
                .iter().filter(|conn_id| *conn_id.to_owned() != msg.id)
                .for_each(|user_id| self.send_message(&format!("{} Disconnected", &msg.id), user_id));
        }

        if let Some(lobby) = self.rooms.get_mut(&msg.room_id) {
            if lobby.len() > 1 {
                lobby.remove(&msg.id);
            } else {
                self.rooms.remove(&msg.room_id);
            }
        }
    }
}

impl Handler<Connect> for Lobby {
    type Result = ();
    fn handle(&mut self, msg: Connect, _: &mut Self::Context) -> Self::Result {
        self.rooms.entry(msg.lobby_id).or_insert_with(HashSet::new).insert(msg.self_id);
        self.rooms.get(&msg.lobby_id).unwrap().iter().filter(|conn_id|{
            *conn_id.to_owned() != msg.self_id
        }).for_each(|conn_id| {
            self.send_message(&format!("{} joined", msg.self_id), conn_id)
        });

        self.sessions.insert(msg.self_id, msg.addr);
        self.send_message(&format!("Your id is {}", msg.self_id), &msg.self_id);
    }
}

impl Handler<ClientActorMessage> for Lobby {
    type Result = ();
    fn handle(&mut self, msg: ClientActorMessage, _: &mut Self::Context) -> Self::Result {
        if msg.msg.starts_with("\\w") {
            if let Some(id_to) = msg.msg.split(" ").collect::<Vec<&str>>().get(1){
                self.send_message(&msg.msg, &Uuid::parse_str(id_to).unwrap());
            }
        } else {
            self.rooms.get(&msg.room_id).unwrap().iter().for_each(|client| {
                self.send_message(&msg.msg, client);
            })
        }
    }
}



const HEARTBEAT_INTERVAL : Duration = Duration::from_secs(5);
const CLIENT_TIMEOUT : Duration = Duration::from_secs(10);




pub struct WsConn {
    pub room: Uuid,
    pub lobby_addr: Addr<Lobby>,
    pub hb: Instant,
    pub id: Uuid
}

impl WsConn {
    pub fn new(room: Uuid, lobby: Addr<Lobby>) -> WsConn {
        WsConn {
            id: Uuid::new_v4(),
            room,
            hb: Instant::now(),
            lobby_addr: lobby
        }
    }
}

impl Actor for WsConn {
    type Context = ws::WebsocketContext<Self>;

    fn started(&mut self, ctx: &mut Self::Context) {
        self.hb(ctx);

        let addr = ctx.address();
        self.lobby_addr.send(Connect{
            addr: addr.recipient(),
            lobby_id: self.room,
            self_id: self.id
        }).into_actor(self).then(|res,_,ctx|{
            match res {
                Ok(_) => (),
                _ => ctx.stop()
            }
            fut::ready(())
        })
            .wait(ctx);
    }

    fn stopping(&mut self, _: &mut Self::Context) -> Running {
        self.lobby_addr.do_send(Disconnect{
            id: self.id,
            room_id: self.room,
        });

        Running::Stop
    }
}

impl WsConn {
    fn hb(&self, ctx: &mut ws::WebsocketContext<Self>) {
        ctx.run_interval(HEARTBEAT_INTERVAL, |act,ctx|{
            if Instant::now().duration_since(act.hb) > CLIENT_TIMEOUT {
                println!("Disconnect due to failed heartbeat!");

                act.lobby_addr.do_send(Disconnect{id: act.id, room_id: act.room});
                ctx.stop();
                return;
            }
            ctx.ping(b"Ping");
        });
    }
}

impl StreamHandler<Result<ws::Message, ProtocolError>> for WsConn {
    fn handle(&mut self, msg: Result<ws::Message, ProtocolError>, ctx: &mut Self::Context) {
        match msg {
                   Ok(ws::Message::Ping(msg)) => {
                        self.hb = Instant::now();
                        ctx.pong(&msg);
                   },
                   Ok(ws::Message::Pong(_)) => {
                        self.hb = Instant::now();
                   },
                   Ok(ws::Message::Text(s)) => self.lobby_addr.do_send(ClientActorMessage{
                                id: self.id,
                                msg: s.parse().unwrap(),
                                room_id: self.room
                   })
                   ,
                   Ok(ws::Message::Nop) => (),
                   Ok(ws::Message::Binary(bin)) => ctx.binary(bin),
                   Ok(ws::Message::Continuation(_)) => ctx.stop(),
                   Ok(ws::Message::Close(reason)) => {
                        ctx.close(reason);
                        ctx.stop();
                   },
                   Err(e) => panic!("{}", e),
        }
    }
}

impl Handler<WsMessage> for WsConn {
    type Result = ();

    fn handle(&mut self, msg: WsMessage, ctx: &mut Self::Context) -> Self::Result {
        ctx.text(msg.0);
    }
}


#[get("/ws/{group_id}")]
pub async fn ws_connect_handler(path: Path<String>, req: HttpRequest, stream: Payload, srv: Data<Addr<Lobby>>) -> impl Responder {
    let group_id = path.into_inner();
    let group_id = group_id.parse::<Uuid>();
    if group_id.is_err() {
        return HttpResponse::BadRequest().json(json!({"status": "Bad group id"}));
    }
    let group_id = group_id.unwrap();

    let ws = WsConn::new(group_id, srv.get_ref().clone());

    ws::start(ws, &req, stream).expect("Reason")
}

