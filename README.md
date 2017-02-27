[![Build Status](https://travis-ci.com/IBM-Swift/CircuitBreaker.svg?token=zkW1banusRzgHu6HwJiN&branch=master)](https://travis-ci.com/IBM-Swift/CircuitBreaker)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)

# CircuitBreaker

## Swift version
The latest version of CircuitBreaker works with the `3.0.2` version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/#releases).

## Usage
To leverage the CircuitBreaker package in your Swift application, you should specify a dependency for it in your `Package.swift` file:

```swift
 import PackageDescription

 let package = Package(
     name: "MySwiftProject",

     ...

     dependencies: [
         .Package(url: "https://github.com/IBM-Swift/CircuitBreaker.git", majorVersion: 0, minor: 0),

         ...

     ])
 ```

### Basic CircuitBreaker usage:

  * The CircuitBreaker state is based on timeouts only

```swift
...

// Define a fallback function with the signature (<BreakerError, (fallbackArg1, fallbackArg2,...)>) -> Void
func testFallback (error: Bool, msg: String) {
    // The fallback will be called if the request does not return before the specified timeout
    // or if the CircuitBreaker is currently in Open state and set to fail fast.
    // Client is expected to use the fallback to do alternate processing, such as show an error page.
    Log.verbose("Error: \(error)")
    Log.verbose("Message: \(msg)")
}

// Test REST endpoint to circuit break
func testEndpoint(input: String, completion: @escaping (JSON, Bool) -> ()) {
    // Create Request
    var req = URLRequest(url: URL(string: "http://testAPIRoute/\(input)")!)
    req.httpMethod = "GET"
    req.allHTTPHeaderFields = ["Content-Type": "application/json"]

    let session = URLSession.shared

    // Perform Request
    session.dataTask(with: req) {result, res, err in
        guard let result = result else {
            let json = JSON("Error: No results.")
            completion(json, true)
            return
        }

        // Convert results to a JSON object
        let json = JSON(data: result)

        completion(json, false)
        }.resume()
}

// Create a CircuitBreaker instant for each endpoint to circuit break
// Must specify the fallback function, and the endpoint to circuit break
// Optional configurations include: timeout, resetTimeout, maxFailures, and bulkhead
let breaker = CircuitBreaker(fallback: testFallback, command: testEndpoint)

// Invoke the call to the endpoint by calling the CircuitBreaker run() function and pass any arguments
breaker.run(commandArgs: (input : "testInput1", { data, err in
    if err {
        print(err)
    } else {
        print(data)
    }
}), fallbackArgs: (msg: "Something went wrong."))

// May be called multiple times with varied input
breaker.run(commandArgs: (input : "testInput2", { data, err in
    if err {
        print(err)
    } else {
        print(data)
    }
}), fallbackArgs: (msg: "Something went wrong."))

...
```

### Advanced CircuitBreaker usage:

  * The CircuitBreaker state is based on timeouts and user defined failures

```swift
...

// Define a fallback function with the signature (<BreakerError, (fallbackArg1, fallbackArg2,...)>) -> Void
func testFallback (err: BreakerError, msg: String) {
    // The fallback will be called if the request does not return before the specified timeout
    // or if the CircuitBreaker is currently in Open state and set to fail fast.
    // Client is expected to use the fallback to do alternate processing, such as show an error page.
    Log.verbose("Error: \(error)")
    Log.verbose("Message: \(msg)")
}

// Test endpoint to circuit break
func sum(a: Int, b: Int) -> (Int) {
    print(a + b)
    return a + b
}

// Create an Invocation wrapper of the endpoint you wish to circuit break
// This allows the user to define and alert the CircuitBreaker of a failure
func sumWrapper(invocation: Invocation<(Int, Int), Int>) -> Int {
    let result = sum(a: invocation.args.0, b: invocation.args.1)
    if result != 7 {
        invocation.notifyFailure()
        return 0
    } else {
        invocation.notifySuccess()
        return result
    }
}

// Create a CircuitBreaker instant for each endpoint to circuit break
// Must specify the fallback function, and the endpoint to circuit break
// Optional configurations include: timeout, resetTimeout, maxFailures, and bulkhead
let breakerAdvanced = CircuitBreaker(fallback: testCallback, commandWrapper: sumWrapper)

// Invoke the call to the endpoint by calling the CircuitBreaker run() function and pass any arguments
breakerAdvanced.run(commandArgs: (a: 3, b: 4), fallbackArgs: (msg: "Something went wrong."))

...
```

## API
### CircuitBreaker

#### Basic Usage Constructor:
```swift
CircuitBreaker(timeout: Double = 10, resetTimeout: Int = 60, maxFailures: Int = 5, bulkhead: Int = 0, callback: @escaping AnyFallback<C>, command: @escaping AnyFunction<A, B>)
```
 * `timeout` Amount in seconds that the request should complete before. Default is set to 10 seconds.
 * `resetTimeout` Amount in seconds to wait before setting to halfopen state. Default is set to 60 seconds.
 * `maxFailures` Number of failures allowed before setting state to open. Default is set to 5.
 * `bulkhead` Number of the limit of concurrent requests running at one time. Default is set to 0, which is equivalent to not using the bulkheading feature.
 * `fallback` Function user specifies to signal timeout or fastFail completion. Required format: `(BreakerError, (fallbackArg1, fallbackArg2,...)) -> Void`
 * `command` Endpoint name to circuit break.

#### Advanced Usage Constructor:
```swift
CircuitBreaker(timeout: Double = 10, resetTimeout: Int = 60, maxFailures: Int = 5, bulkhead: Int = 0, callback: @escaping AnyFallback<C>, commandWrapper: @escaping AnyFunctionWrapper<A, B>)
```
 * `timeout` Amount in seconds that the request should complete before. Default is set to 10 seconds.
 * `resetTimeout` Amount in seconds to wait before setting to halfopen state. Default is set to 60 seconds.
 * `maxFailures` Number of failures allowed before setting state to open. Default is set to 5.
  * `bulkhead` Number of the limit of concurrent requests running at one time. Default is set to 0, which is equivalent to not using the bulkheading feature.
 * `fallback` Function user specifies to signal timeout or fastFail completion. Required format: `(BreakerError, (fallbackArg1, fallbackArg2,...)) -> Void`
 * `commandWrapper` Wrapper around endpoint name to circuit break, allow user defined failures.

### CircuitBreaker Stats
```swift
...
// Create CircuitBreaker
let breaker = CircuitBreaker(fallback: tesFallback, command: testEndpoint)

// Invoke breaker call
breaker.run(args: (input: "test"))

// Log Stats snapshot
breaker.snapshot()
...
```

#### Tracked Stats:
 * Total Requests
 * Concurrent Requests
 * Rejected Requests
 * Successful Responses
 * Average Response Time
 * Failed Responses
 * Total Timeouts
 * Total Latency

## License
This Swift package is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
