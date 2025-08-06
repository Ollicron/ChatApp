import asyncdispatch, asyncnet

type
    Client = ref object
        socket: AsyncSocket
        netAddr: string
        id: int
        connected: bool

    Server = ref object
        socket: AsyncSocket
        clients: seq[Client]

# This function creates a new server and returns it.
proc makeNewServer*(port:int = 7777): Server = 
    let newServer = Server(socket: newAsyncSocket(), clients: @[])
    # Bind the address and port number, default address is localhost.
    newServer.socket.bindAddr(Port(port))
    # Ready the server socket for new connections.
    newServer.socket.listen()
    echo("Listening on localhost:", port)
    return newServer

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
        server.clients.add(newClient)


when isMainModule:
    let someServer = makeNewServer()
    
    #[ We are discarding the future, but we want this to run asynchronously with run forever ]#
    discard acceptConnections(someServer)


    runForever()