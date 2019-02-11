import Foundation
import LoxInterpreter
import CommandLineKit
#if os(Linux)
import Glibc
#else
import Darwin
#endif

do {
    let args = CommandLine.arguments
    let numArgs = args.count
    
    guard numArgs <= 2 else {
        print("Usage: lox [script]")
        exit(1)
    }
    
    let lox = LoxInterpreter()
    
//    if true { // numArgs == 2 {
//        let path = "/tmp/t.lox" //args[1]
    if numArgs == 2 {
        let path = args[1]

        let bytes = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let source = String(bytes: bytes, encoding: .utf8) else {
            fatalError("Invalid file")
        }
        exit(lox.run(source: source))
    } else {
        let lineReader = LineReader()!
        
        while true {
            let line = try lineReader.readLine(prompt: "> ",
                                               maxCount: nil,
                                               strippingNewline: true,
                                               promptProperties: TextProperties(textColor: .blue, backgroundColor: nil, textStyles: []),
                                               readProperties: TextProperties(),
                                               parenProperties: TextProperties())
            lineReader.addHistory(line)
            _ = lox.run(source: line)
        }
    }
}
catch {
    exit(handle(error))
}
