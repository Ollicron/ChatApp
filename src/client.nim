import 
    os,asyncdispatch,asyncfile,
    asyncnet

echo ("Initiating Chat Client")
if paramCount() == 0:
    quit("Please specify the server address, e.g. ./client localhost")

let serverAddr = paramStr(1)

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

# This is to send a message asynchronously
proc sendMessage(message:string, clientSocket:AsyncSocket) {.async.} =
    asyncCheck send(clientSocket,message & "\c\L")
    echo "message sent!"

# This is to asynchronously take input from the user
proc takeInput():Future[string]{.async.}=
    let temp = openAsync("/dev/stdout", fmWrite)
    await write(temp,">")
    let file = openAsync("/dev/stdin",fmReadWrite)
    let message = await asyncfile.readLine(file)
    
    return message
    
proc main() {.async.} =
    # Connect to the server
    let client = await connectToServer(serverAddr)
    while true:
        let message = await takeInput()
        asyncCheck sendMessage(message, client)
        if message == "":
            await sleepAsync(20)
            quit("Exiting!")

    
# Technically we're not waiting for anything.
asyncCheck main()