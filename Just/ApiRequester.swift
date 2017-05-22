//
//  ApiRequester.swift
//  Just
//
//  Created by Krzysztof Kapitan on 14.05.2017.
//  Copyright © 2017 CappSoft. All rights reserved.
//

import Alamofire
import JSONCodable

enum ApiResponse<T> {
    case success(T)
    case failure(Error?)
}

struct Adapter: RequestAdapter {
    fileprivate let storage: KeychainStorage
    
    init(keychain: KeychainStorage) {
        self.storage = keychain
    }
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var mutable = urlRequest
        
        if let token = storage.getUser()?.token {
            mutable.setValue(token, forHTTPHeaderField: "Authorization")
        }
        
        return mutable
    }
}

final class ApiRequester {
    fileprivate let manager: SessionManager
    
    init(manager: SessionManager = .default) {
        self.manager = manager
        manager.adapter = Adapter(keychain: .init())
    }
    
    func request<T:JSONDecodable>(request: Request, params: RequestParams? = nil, completion: @escaping (ApiResponse<T>) -> ()) {
        manager.request(request.url, method: request.method, parameters: params?.params, encoding: JSONEncoding(), headers: nil)
            .validate()
            .responseJSON { result in
                
                guard let object = result.value
                    .flatMap({ $0 as? [String: Any] })
                    .flatMap({ try? T(object: $0) })
                else {
                    completion(.failure(result.error))
                    return
                }

                completion(.success(object))
        }
    }
    
    func request<T:JSONDecodable>(request: Request, params: RequestParams? = nil, completion: @escaping (ApiResponse<[T]>) -> ()) {
        manager.request(request.url, method: request.method, parameters: params?.params, encoding: JSONEncoding(), headers: nil)
            .validate()
            .responseJSON { result in
                
                guard let objects = result.value
                    .flatMap({ $0 as? [[String: Any]] })
                    .flatMap({ try? [T](JSONArray: $0) })
                    else {
                        completion(.failure(result.error))
                        return
                }
                
                completion(.success(objects))
        }
    }
    
    func request(request: Request, params: RequestParams? = nil, completion: @escaping (ApiResponse<Void>) -> ()) {
        manager.request(request.url, method: request.method, parameters: params?.params, encoding: JSONEncoding(), headers: nil)
            .validate()
            .responseJSON { result in
                
                if let error = result.error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
        }
    }
}

import RxSwift

extension ApiRequester {
    
    fileprivate func _request(request: Request, params: RequestParams? = nil) -> Observable<Result<Any>> {
        let manager = self.manager
        
        return Observable.create { observer -> Disposable in
        
            manager.request(request.url, method: request.method, parameters: params?.params, encoding: JSONEncoding(), headers: nil)
                .validate()
                .responseJSON { response in
                    observer.onNext(response.result)
                    observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func request(request: Request, params: RequestParams? = nil) -> Observable<ApiResponse<Void>> {
        return self._request(request: request, params: params).map {
            if let error = $0.error {
                return .failure(error)
            }
            
            return .success(())
        }
    }
    
    func request<T: JSONDecodable>(request: Request, params: RequestParams? = nil) -> Observable<ApiResponse<T>> {
        return self._request(request: request, params: params)
            .map {
                if let json = $0.value as? [String: Any], let object = try? T(object: json) {
                    return .success(object)
                } else {
                    return .failure($0.error)
                }
            }
    }

    func request<T: JSONDecodable>(request: Request, params: RequestParams? = nil) -> Observable<ApiResponse<[T]>> {
        return self._request(request: request, params: params)
            .map {
                if let jsons = $0.value as? [[String: Any]], let objects = try? [T](JSONArray: jsons) {
                    return .success(objects)
                } else {
                    return .failure($0.error)
                }
            }
    }
}
