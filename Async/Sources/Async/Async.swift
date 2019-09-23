import Foundation

typealias AsyncResult<T> = (Result<T, Error>) -> Void


class Async<T> {
    private var block: (Any, @escaping AsyncResult<T>) -> Void
    var state: Any? = nil
    private var onError: ((Error) -> Void)?
    
    init(block: @escaping (AsyncResult<T>) -> Void) {
        self.block = { _, result -> Void in
            block(result)
        }
    }
    
    init(block: @escaping (Any, @escaping AsyncResult<T>) -> Void) {
        self.block = block
    }
    
    func then<U>(_ next: @escaping (T, @escaping AsyncResult<U>) -> Void) -> Async<U> {
        let semaphore = DispatchSemaphore(value: 0)
        var async: Async<U>? = nil
        let queue = DispatchQueue.global()
        queue.async {
            self.block(self.state) { result in
                switch result {
                case .success(let newState):
                    async = Async<U> { s, ar in
                        next(s as! T, ar)
                    }
                    async?.state = newState
                    semaphore.signal()
                case .failure(let error):
                    self.onError?(error)
                }
            }
        }
        semaphore.wait()
        return async!
    }
    
    func done(_ body: @escaping (T) -> Void) -> Async<T>{
        self.block(self.state) { result in
            switch result {
            case .success(let value):
                body(value)
            case .failure(let error):
                self.onError?(error)
            }
        }
        return self
    }
    
    func map<U, G>(_ body: @escaping (MapFunction<U, G>) -> Void) -> Async<G> {
        return self.then { value, asyncResult in
            body { mapper in
                return { result in
                    switch result {
                    case .success(let projected):
                        asyncResult(.success(mapper(value, projected)))
                    case .failure(let error):
                        asyncResult(.failure(error))
                    }
                }
            }
        }
    }
    
    func `catch`(_ handler: @escaping (Error) -> Void) {
        self.onError = handler
    }
}

typealias MapFunction<U, V> = (@escaping (Any, U) -> V) -> AsyncResult<U>

