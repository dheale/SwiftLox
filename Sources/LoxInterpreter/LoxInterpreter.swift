import Foundation

struct Lox {
    struct Constants {
        static let maxNumberOfFunctionArguments = 8
    }
}

public class LoxInterpreter {
    public init() {}
    
    public enum Error: Swift.Error {
        case invalidInputFile
    }
    
    var hadError = false
    var hadRuntimeError = false

    private func error(_ line: Int, _ message: String) {
        report(line, "", message)
    }
    
    private func report(_ line: Int, _ `where`: String, _ message: String) {
        fputs("[line \(line)] \(`where`): \(message)\n", stderr)
        hadError = true
    }
    
    func error(_ token: Token, _ message: String) {
        if token.type == .eof {
            report(token.lineNumber, "Error at end", message)
        } else {
            report(token.lineNumber, "Error at '\(token.lexeme)'", message)
        }
    }
    
    private func runtimeError(_ error: RuntimeError) {
        _ = handle(error)
//        fputs("\(error.message)\n[line \(String(error.token.lineNumber))]\n", __stderrp)
        hadRuntimeError = true
    }
    
    public func run(source: String) -> Int32  {
        let tokenizer = Tokenizer(source: source)
        let resolver = Resolver(interpreter: self)
        
        do {
            let tokens = try tokenizer.tokenize()
            let p = try Parser(tokens: tokens, interpreter: self).parse()
            if hadError {
                return 65
            }
            
            let resolved = p.map { resolver.resolve($0) }
            
            if hadError {
                return Parser.Error.returnCode
            }
            
            for r in resolved {
                try r.execute(Environment.global)
            }
        }
        catch {
            return handle(error)
        }
        
        return 0
    }
    
    public func runFile(_ path: String) throws -> Int32 {
        let bytes = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let source = String(bytes: bytes, encoding: .utf8).nonEmpty else {
            throw Error.invalidInputFile
        }
        return run(source: source)
    }
}

public
func handle(_ error: Error) -> Int32 {
    if let e = error as? RuntimeError {
        fputs(e.message + "\n", stderr)
        return RuntimeError.returnCode
    }
    else if let e = error as? Parser.Error {
        fputs(e.message, stderr)
        return Parser.Error.returnCode
    }
    else if error is Tokenizer.TokenizeError {
        return 65
    }
    
    return RuntimeError.returnCode
}
