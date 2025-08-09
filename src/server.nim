import asyncdispatch, asyncnet,locks

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
        lock: Lock


# This function creates a new server and returns it.
proc makeNewServer*(port:int = 7777): Server = 
    let newServer = Server(socket: newAsyncSocket(), clients: @[])

    # Initialize the lock in the server
    locks.initLock(newServer.lock)
    # Let the socket reuse the same address as before
    newServer.socket.setSockOpt(OptReuseAddr, true)
    # Bind the address and port number, default address is localhost.
    newServer.socket.bindAddr(Port(port))
    # Ready the server socket for new connections.
    newServer.socket.listen()
    echo("Listening on localhost:", port)
    return newServer

proc broadcastMessage(message: string, sender: Client, server: Server) {.async.} =
  var clientsSnapshot: seq[Client]
  # grab a snapshot safely
  withLock server.lock:
    clientsSnapshot = server.clients[0 .. server.clients.len-1]
  for client in clientsSnapshot:
    if client != sender:
      await client.socket.send(message & "\c\L")

# We need to process messages from clients. To do this we need to to ingest data from their sockets.
proc processMessages(client:Client, server:Server) {.async.}=
    while true:
        # Ingest the message
        let message = await client.socket.recvLine()
        echo "Message received from",client.id,":",message

        await broadcastMessage(message,client,server)

        # # DANGER: server.clients can be accessed while updating.
        # # Task: need to protect server.clients.
        # for otherClient in server.clients:
        #     if otherClient != client:
        #         await otherClient.socket.send(message & "\c\L")

        
        #wait 10 milliseconds to give CPU time to breathe
        await sleepAsync(10)

# Add a new client while using the lock
proc addClient(server: Server, newClient: Client) =
  withLock server.lock:
    server.clients.add(newClient)

# Because we want this to be ongoing we need this to run forever.
proc acceptConnections(server: Server){.async.} =
    while true:
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
        var id:int
        withLock server.lock:  
            id = server.clients.len + 1  
        newClient.id = id  
        
        # Add the client into the server's sequence
        addClient(server,newClient)

        echo("Number of clients: ", server.clients.len())

        # Start processing messages for the client immediately
        asyncCheck processMessages(newClient,server)


proc main() =
    var chatServer = makeNewServer()

    asyncCheck acceptConnections(chatServer)

     # We need the event loop to run forever; if not, then main ends and so does the program
    try:
        runForever()
    except ValueError:
        # The program will crash if the event loop has nothing in it, it's better to handle things gracefully.
        quit("Event loop empty!")
    


main()