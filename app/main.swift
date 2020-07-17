import Foundation

let server = try! Server.make(arguments: CommandLine.arguments)
print("Server created with URL '\(server.url)' and player key '\(server.playerKey)'")

switch server.performPost() {
case .success(let body):
    print("Server response: \(body)")
case .failure(let error):
    print("Unexpected server response: \(error)")
    exit(-1)
}
