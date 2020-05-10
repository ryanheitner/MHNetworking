import XCTest
@testable import MHNetworking

final class MHNetworkingTests: XCTestCase {
    let startURLString = "5e0af46b3300007e1120a7ef"
    let myID = "rhe01:"
    func test1() {
        // We expect a circular reference error
        // we force this by adding the keyword to the end of the url
        // This is not really a very good test , would be better If we had a server with a circular reference

        print("start:\(#function)")
        let numberOfRedirectsAllowed = 7
        let exp = self.expectation(description: "highExpectation")
        MHNetworkManager().getRequest(urlString: startURLString + MHConstants.circularRedirectKeyword, success: { responseDictionary in
            print("\(self.myID) success \(#function) \(responseDictionary)")
            exp.fulfill()
            XCTAssertTrue(false,"\(self.myID) \(#function) is supposed to fail with error")
        }, failure: { error in
            print("\(self.myID) fail \(#function) \(error)")
            var isCorrectError = false
            if case MHError.circularRedirect = error {
                isCorrectError = true
            }
            exp.fulfill()
            XCTAssertTrue(isCorrectError, "\(self.myID) error \(#function) \(error.errorDescription) : \(isCorrectError)")
        }, redirectLimit: numberOfRedirectsAllowed)

        waitForExpectations(timeout: 5, handler: nil)
    }
    func test2() {
        print("start:\(#function)")
        // We expect to Get an error too many redirects
        let numberOfRedirectsAllowed = 2
        let exp = self.expectation(description: "lowExpexctation")
        MHNetworkManager().getRequest(urlString: startURLString, success: { responseDictionary in
            print("\(self.myID) success \(#function) \(responseDictionary)")
            exp.fulfill()
            XCTAssertTrue(false,"\(self.myID) \(#function) is supposed to fail with error")
        }, failure: { error in
            print("\(self.myID) fail \(#function) \(error)")
            var isCorrectError = false
            if case MHError.tooManyRedirects = error {
                isCorrectError = true
            }
            exp.fulfill()
            XCTAssertTrue(isCorrectError, "\(self.myID) error \(#function) \(error.errorDescription) : \(isCorrectError)")
        }, redirectLimit: numberOfRedirectsAllowed)

        waitForExpectations(timeout: 5, handler: nil)
    }
    func test3() {
        // We expect to no error
        print("start:\(#function)")
        let numberOfRedirectsAllowed = 7
        let exp = self.expectation(description: "highExpectation")
        MHNetworkManager().getRequest(urlString: startURLString, success: { responseDictionary in
            print("\(self.myID) success \(#function) \(responseDictionary)")
            exp.fulfill()
            XCTAssert(!responseDictionary.isEmpty)

        }, failure: { error in
            print("\(self.myID) fail \(#function) \(error)")
            exp.fulfill()
            XCTAssertTrue(false,"\(self.myID) \(#function) is supposed to succeed but has error \(error)")
        }, redirectLimit: numberOfRedirectsAllowed)

        waitForExpectations(timeout: 5, handler: nil)
    }

    
    
    static var allTests = [
        ("test1", test1),
        ("test2", test2),
        ("test3", test3),
        
    ]
}
