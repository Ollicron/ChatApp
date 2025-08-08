import asyncdispatch, asyncnet

type
    Client = ref object
        socket: AsyncSocket
        netAddr: string
        id: int
        connected: bool

    # Personally I'm not a fan of putting sequences like this in an object
    Server = ref object
        socket: AsyncSocket
        clients: seq[Client]

# This function creates a new server and returns it.
proc makeNewServer*(port:int = 7777): Server = 
    let newServer = Server(socket: newAsyncSocket(), clients: @[])
    # Let the socket reuse the same address as before
    newServer.socket.setSockOpt(OptReuseAddr, true)
    # Bind the address and port number, default address is localhost.
    newServer.socket.bindAddr(Port(port))
    # Ready the server socket for new connections.
    newServer.socket.listen()
    echo("Listening on localhost:", port)
    return newServer

# Because we want this to be ongoing we need this to run forever.
proc acceptConnections(server: Server){.async.} =

    # Pause execution of this procedure until a new connection is accepted.
    let (clientAddr,clientSocket) = await server.socket.acceptAddr()

    echo ("Accepted connection from:",clientAddr)
    # Populate a new client object and store it.
    let newClient = Client(
        socket: clientSocket,
        netAddr: clientAddr,
        id:0,
        connected: true
    )
    # Set the client Id
    for i in 0..server.clients.len()-1:
        server.clients[i].id = i + 1
    
    server.clients.add(newClient)

    echo("Number of clients: ", server.clients.len())

# A function to broadcast any received messages to the clients
proc broadcastMessage(message: string,server:Server){.async.}=
    for client in server.clients:
        asyncCheck client.socket.send(message & "\c\L")

# We need to process messages from clients. To do this we need to to ingest data from their sockets.
proc processMessages(server: Server, clientIndex:int) {.async.}=
    while true:
        let message = await server.clients[clientIndex].socket.recvLine()
        echo "Received message from client ", server.clients[clientIndex].id,":", message

        if message == "\c\L":
            server.clients[clientIndex].socket.close()
            delete(server.clients,clientIndex)
            echo("Number of clients left:", server.clients.len)
            break

        asyncCheck broadcastMessage(message,server)

proc main(){.async.} =
    var someServer = makeNewServer()

    # We need to continuously accept any new connections that come in so this needs to repeat. 
    while true:
        await acceptConnections(someServer)
        # If we have accepted the first connection then start processing messages from the socket
        if someServer.clients.len > 0:
            for i in 0 .. someServer.clients.len()-1:
                asyncCheck processMessages(someServer, i)


waitFor main()