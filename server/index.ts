import { randomUUIDv7, type ServerWebSocket } from 'bun';

type ClientType = 'user' | 'robot';

type FromHostMessageType =
    | 'host_listUsers'
    | 'host_pairConnect'
    | 'host_pairDisconnect';
type FromUserMessageType = 'user_pairConnect' | 'user_pairDisconnect';
type BetweenClientsMessageType = 'client_message';
interface SocketMessage {
    type: FromHostMessageType | FromUserMessageType | BetweenClientsMessageType;
    data: any;
}

type WebSocketData = {
    id: string;
    createdAt: number;
    clientType: ClientType;
    pairedWith?: ServerWebSocket<WebSocketData>;
};

const allClients = new Map<string, ServerWebSocket<WebSocketData>>();

const CHANNEL_AVAILABLE_CLIENTS = 'available-clients';
const publishAvailableClients = (ws: ServerWebSocket<WebSocketData>) => {
    const message: SocketMessage = {
        type: 'host_listUsers',
        data: Array.from(
            allClients
                .values()
                .filter(({ data: { pairedWith } }) => !Boolean(pairedWith))
                .map(({ data: { id, createdAt, clientType } }) => ({
                    id,
                    createdAt,
                    clientType,
                }))
        ),
    };

    ws.publish(CHANNEL_AVAILABLE_CLIENTS, JSON.stringify(message));
};

const server = Bun.serve<WebSocketData>({
    async fetch(req, server) {
        const url = new URL(req.url);

        if (url.pathname === '/' && req.method === 'GET')
            return new Response('Hello World!');
        if (url.pathname === '/ws') {
            if (
                server.upgrade(req, {
                    data: {
                        id: randomUUIDv7(),
                        createdAt: Date.now(),
                        clientType: url.searchParams.get(
                            'clientType'
                        ) as ClientType,
                    },
                })
            )
                return;

            return new Response('Upgrade failed', { status: 500 });
        }

        return new Response('404!');
    },
    websocket: {
        open(ws) {
            console.log('WebSocket opened', ws.data);

            allClients.set(ws.data.id, ws);
            if (ws.data.clientType === 'user')
                ws.subscribe(CHANNEL_AVAILABLE_CLIENTS);

            publishAvailableClients(ws);
        },
        close(ws) {
            console.log('WebSocket closed', ws.data);

            allClients.delete(ws.data.id);
            if (ws.data.pairedWith) {
                const message: SocketMessage = {
                    type: 'host_pairDisconnect',
                    data: 'Partner disconnected',
                };
                ws.data.pairedWith.send(JSON.stringify(message));
                ws.data.pairedWith.data.pairedWith = undefined;

                publishAvailableClients(ws);
            }
        },
        message(ws, event) {
            const message: SocketMessage = JSON.parse(event.toString());
            if (ws.data.pairedWith) {
                switch (message.type) {
                    case 'user_pairDisconnect':
                        if (ws.data.pairedWith) {
                            const message: SocketMessage = {
                                type: 'host_pairDisconnect',
                                data: ws.data.id,
                            };
                            ws.send(JSON.stringify(message));
                            ws.data.pairedWith.send(JSON.stringify(message));
                        }

                        publishAvailableClients(ws);
                        break;

                    default:
                        const newMessage: SocketMessage = {
                            type: 'client_message',
                            data: JSON.parse(event.toString()),
                        };
                        ws.data.pairedWith.send(JSON.stringify(newMessage));
                        return;
                }
            } else {
                if (ws.data.clientType === 'user') {
                    switch (message.type) {
                        case 'user_pairConnect':
                            const robotID = message.data as string;
                            const robot = Array.from(allClients.values()).find(
                                (client) =>
                                    client.data.clientType === 'robot' &&
                                    !client.data.pairedWith &&
                                    client.data.id === robotID
                            );

                            if (robot) {
                                ws.data.pairedWith = robot;
                                robot.data.pairedWith = ws;

                                const message: SocketMessage = {
                                    type: 'host_pairConnect',
                                    data: ws.data.id,
                                };
                                ws.send(JSON.stringify(message));
                                robot.send(JSON.stringify(message));

                                publishAvailableClients(ws);
                            }
                            break;
                        default:
                            console.warn(
                                `Unknown message type: ${message.type}`
                            );
                            return;
                    }
                }
            }
        },
    },
});

console.log(`Listening on ${server.url}`);
