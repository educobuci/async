import Quick
import Nimble
import Foundation
@testable import Async

final class AsyncTests: QuickSpec {
    override func spec() {
        describe("async") {
            it("should work") {
                waitUntil { done in
                    Async { get(url: "url", completion: $0) }
                        .then { response, next in
                            get(url: "\(response!)_url2", completion: next)
                        }
                        .then { response, next in
                            expect(response) == "url_url2"
                            done()
                        }
                        .resume()a
                }
                
            }
        }
    }
}

typealias AsyncResult = (Result<String, Error>) -> Void
func get(url: String, completion: AsyncResult) {
    completion(.success(url))
}

class Async {
    var block: ((String?, AsyncResult) -> Void)
    var state: String? = nil
    
    init(block: @escaping (AsyncResult) -> Void) {
        self.block = { (_, result) in
            block(result)
        }
    }
    
    init(block: @escaping (String?, AsyncResult) -> Void) {
        self.block = block
    }
    
    func then(next: @escaping (String?, AsyncResult) -> Void) -> Async {
        let semaphore = DispatchSemaphore(value: 0)
        var async: Async?
        let queue = DispatchQueue.global()
        queue.async {
            self.block(self.state) { result in
                switch result {
                case .success(let newState):
                    async = Async(block: next)
                    async?.state = newState
                    semaphore.signal()
                default:
                    print("Error")
                }
            }
        }
        semaphore.wait()
        return async!
    }
    
    func resume() {
        self.block(self.state) { result in
        }
    }
}
