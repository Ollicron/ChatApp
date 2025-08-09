import 
    os,asyncdispatch,asyncfile,
    asyncnet

if paramCount() == 0:
    quit("Please specify the server address, e.g. ./client localhost")

let serverAddr = paramStr(1)

#[ Connecting to the server ]#

# This is to connect to the server
proc connectToServer(address:string):Future[AsyncSocket] {.async.}=
    let clientSocket = newAsyncSocket()
    echo "Connecting to " & serverAddr
    try:
        await connect(clientSocket,address,Port(7777))
        echo "Connected!"
        result = clientSocket
    except:
        quit("Incorrectly entered address")


#[ Receiving Messages ]#


# This is to receive a message asynchronously
proc recvMessage(clientSocket: AsyncSocket) {.async.}=
    let temp = openAsync("/dev/stdout", fmWrite)
    while true:
        let incomingMessage = await clientSocket.recvLine()
        echo incomingMessage
        asyncCheck write(temp,"\n>")
        

#[ Sending Messages ]#


# This is to asynchronously take input from the user
proc takeInput():Future[string]{.async.}=
    let file = openAsync("/dev/stdin",fmReadWrite)
    var message = await asyncfile.readLine(file)
    if message == "\c\L":
        await sleepAsync(20)
        quit("Exiting!")
    return message

# This is to send a message asynchronously
proc sendMessage(clientSocket:AsyncSocket) {.async.} =
    while true:
        #Construct the message here
        let message = await takeInput()
        asyncCheck send(clientSocket, message & "\c\L")


#[ Main ]#


proc main() =
    echo ("Initiating Chat Client")

    # We use waitFor here because it's the "await" for synchronous functions 
    let client = waitFor connectToServer(serverAddr)

    # Start the two main functions asynchronously
    asyncCheck sendMessage(client)
    asyncCheck recvMessage(client)
    
    # We need the event loop to run forever; if not, then main ends and so does the program
    try:
        runForever()
    except ValueError:
        # The program will crash if the event loop has nothing in it, it's better to handle things gracefully.
        quit("Event loop empty!")

main()
