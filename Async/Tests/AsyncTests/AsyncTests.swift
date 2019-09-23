import Quick
import Nimble
import Foundation

@testable import Async

final class AsyncTests: QuickSpec {
    override func spec() {
        describe("async") {
            it("should wrap a single async call and pass the result to done") {
                waitUntil { done in
                    let _ = Async { rng(completion: $0) }
                        .done {
                            expect($0) == 3
                            done()
                        }
                }
            }
            it("should wrap any number of async calls and pass the result to done") {
                waitUntil { done in
                    let _ = Async { foward(text: "text", completion: $0) }
                        .then { foward(text: "\($0)1", completion: $1) }
                        .then { foward(text: "\($0)2", completion: $1) }
                        .done {
                            expect($0) == "text12"
                            done()
                        }
                }
            }
            it("should allow map transformation") {
                waitUntil { done in
                    let _ = Async { foward(text: "text", completion: $0) }
                        .map {
                            rng(completion: $0 { ["key": "\($0)\($1)"] })
                        }.done {
                            expect($0["key"]) == "text3"
                            done()
                        }
                }
            }
        }
        
        func foward(text: String, completion: AsyncResult<String>) {
            completion(.success(text))
        }

        func rng(completion: AsyncResult<Int>) {
            completion(.success(3)) // Totally random
        }
    }
}
