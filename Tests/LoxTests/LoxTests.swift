import XCTest
import class Foundation.Bundle

final class LoxTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let loxBinary = productsDirectory.appendingPathComponent("Lox")

        
        let testBundle = Bundle(for: type(of: self)).resourceURL!
        let inputFiles = try FileManager.default.contentsOfDirectory(at: testBundle, includingPropertiesForKeys: nil, options: [])
            .filter { $0.pathExtension == "lox" }
        
        for file in inputFiles {
            let task = Process()
            task.executableURL = loxBinary
            
            task.arguments = [file.path]
            
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.launch()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data,
                                encoding: String.Encoding.utf8) ?? "No output"
            task.waitUntilExit()
            
            XCTAssertEqual(output, "0.0\n1.0\n4.0\n9.0\n")
        }
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
    
    var TestInputsDir: URL {

        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")

    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
