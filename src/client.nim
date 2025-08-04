import 
    os,threadpool

echo ("Initiating Chat Client")
if paramCount() == 0:
    quit("Please specify the server address, e.g. ./client localhost")

let serverAddr = paramStr(1)
echo ("Connecting to ",serverAddr)

while true:
    let message = spawn stdin.readLine()
    echo("Sending \"", ^message,"\"")

