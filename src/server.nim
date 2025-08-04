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

proc newServer*(): Server=
  Server(socket:newAsyncSocket, clients: @[])