//
//  MHNetworkManager.swift
//  Maccabi
//
//  Created by Ryan Heitner on 08/05/2020.
//  Copyright © 2020 Ryan Heitner. All rights reserved.
//


import Foundation

public enum MHError: Error {
    case tooManyRedirects
    case circularRedirect
    case unableToComplete
    case invalidResponse(response:Int)
    case invalidData
}

extension MHError {
    var errorDescription : String {
        switch self {
        case .tooManyRedirects: return "The number of 301 redirects has exceeded the limit"
        case .circularRedirect: return "Circular redirect path detected"
        case .unableToComplete: return "Unable to complete your request. Please check your internet connection."
        case .invalidResponse:  return "Invalid response from the server. Please try again."
        case .invalidData:      return "The data received from the server was invalid. Please try again."
        }
    }
}

// The network manager has the following features
// 1) Limit the number of 301 redirects for get requests
// 2) Detect Circular Redirects, this can happen if a webpage redirects to another which in turn redirects back to itself or similar
public class MHNetworkManager : NSObject {
    
    public typealias SuccessHandler = (_ json : [String:Any]) -> ()
    public typealias ErrorHandler = (_ error : MHError) -> ()
    
    // MARK: Private Vars
    private var baseURL : URL?
    private var redirectCount = 0
    private var redirectLimit = Int.max // unlimited redirects as default
    private var circularRedirectDetected = false
    #if DEBUG
    // it is dificult to dest for circular redirects this is to allow unit testing
    // it is a contrived test
    private var mockCircularRedirectURL = false
    #endif
    
    private var urlsVisitedSet : Set<URL> = []
    private var urlSession : URLSession?
    
    
    
    lazy var defaultSession:URLSession = {
        let config = URLSessionConfiguration.default
        // We set the qos to utility so that outr API does not impact UI Thread
        let delegateQueue = OperationQueue()
        delegateQueue.qualityOfService = .utility
        return URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
    }()
    
    // URL For Testing
    private let defaultURL : URL = URL(string: "http://www.mocky.io/v2/")!
    
    public init(baseURL:URL? = nil){
        super.init()
        self.baseURL = baseURL ?? defaultURL
        self.redirectCount = 0
        self.redirectLimit = Int.max
        self.circularRedirectDetected = false
        urlsVisitedSet.removeAll()
    }
    
    
    // redirect limit is optional, it will limit the number of 301/302 redirects
    public func getRequest(urlString:String,
                           success: @escaping (SuccessHandler),
                           failure: @escaping (ErrorHandler),
                           redirectLimit:Int = Int.max)
    {
        self.redirectLimit = redirectLimit
        
        var myUrlString = urlString
        #if DEBUG
        //        It is difficult to unit test for a circular redirect because this is dependent on the HTTP Server
        //        To allow this we have a keyword at the end of the URL
        if urlString.hasSuffix(MHConstants.circularRedirectKeyword) {
            mockCircularRedirectURL = true
            myUrlString = String(urlString.dropLast(MHConstants.circularRedirectKeyword.count))
        }
        #endif
        
        let url = self.baseURL!.appendingPathComponent(myUrlString)
        
        // Keep track of URLs called to detect circular redirects
        
        urlsVisitedSet.insert(url)
        let urlRequest = URLRequest(url: url)
        let task = defaultSession.dataTask(with: urlRequest, completionHandler: { (data,response,error) -> () in
            
            guard error == nil else {
                failure(.unableToComplete)
                return
            }
            guard let data = data else {
                failure(.invalidData)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                failure(.invalidResponse(response: 0))
                return
            }
            // InValid HTTP Response codes 200-299
            // we escape with a error code
            guard (200...299 ~= response.statusCode) else {
                switch response.statusCode {
                case 301:
                    if self.redirectCount >= self.redirectLimit {
                        failure(.tooManyRedirects)
                    } else if self.circularRedirectDetected {
                        failure(.circularRedirect)
                    } else {
                        failure(.invalidResponse(response: response.statusCode))
                    }
                default:
                    failure(.invalidResponse(response: response.statusCode))
                }
                return
            }
            
            
            // We have a valid response
            do {
                let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                if let myDict = responseJSON as? [String:Any] {
                    success(myDict)
                } else {
                    failure(.invalidData)
                }
            } catch {
                failure(.invalidResponse(response: response.statusCode))
            }
            
        })
        task.resume()
    }
    
}

// Delegate URLSessionTaskDelegate detects 301 redirects
extension MHNetworkManager : URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // 301 Moved Permanently we are not handling any other codes
        guard response.statusCode == 301 else {
            completionHandler(request)
            return
        }
      
//
// MARK: Detect Circular References
//
        // If the redirect URL is already a url which we have visited this means we have a circular reference and should exit
        if let nextUrl = request.url ,
            urlsVisitedSet.contains(nextUrl) {
            self.circularRedirectDetected = true
            completionHandler(nil)
            return
        }
//
// MARK: Test if Redirect limit has been exceeded
//
        redirectCount += 1
        if redirectCount >= redirectLimit {
            completionHandler(nil)
            return
        }
        
        
        // This debug code is to unit test circular url calls
        // since it is difficult to test this without setting up an http webserver
        // we have a way of forcing a circular reference to occur
        #if DEBUG
        if (request.url != nil)
            ,mockCircularRedirectURL == true
            ,request.url!.absoluteString.hasSuffix(MHConstants.circularRedirectURLFrom) {
            
            var newRequest = request
            let urlString = request.url!.absoluteString.replacingOccurrences(of: MHConstants.circularRedirectURLFrom, with: MHConstants.circularRedirectURLTo)
            newRequest.url = URL(string: urlString)
            completionHandler(newRequest)
            return
            
        }
        #endif
        
        //
        // MARK: Save vistited urls to Detect a Circular Reference
        //
        if (request.url != nil) {
            urlsVisitedSet.insert(request.url!)
        }
        
        completionHandler(request)
    }
}
