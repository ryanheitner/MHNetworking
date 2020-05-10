import XCTest
@testable import MHNetworking

final class MHNetworkingTests: XCTestCase {
    func test2() {
        print("test2")

        // We expect to Get an error too many redirects
        let numberOfRedirectsAllowed = 2
        let exp = self.expectation(description: "lowExpexctation")
        let urlString = "5e0af46b3300007e1120a7ef"
        MHNetworkManager().getRequest(urlString: urlString, success: { responseDictionary in
            print("rhe01 success 2 \(responseDictionary)")
            exp.fulfill()
            XCTAssert(!responseDictionary.isEmpty)

        }, failure: { error in
            print("rhe01 fail 2 \(error)")
            var isCorrectError = false
            if case MHError.tooManyRedirects = error {
                isCorrectError = true
            }
            exp.fulfill()
            XCTAssertTrue(isCorrectError)
        }, redirectLimit: numberOfRedirectsAllowed)

        waitForExpectations(timeout: 5, handler: nil)
    }
    func test3() {
        // We expect to no error
        print("test3")

        let numberOfRedirectsAllowed = 7
        let exp = self.expectation(description: "highExpectation")
        let urlString = "5e0af46b3300007e1120a7ef"
        MHNetworkManager().getRequest(urlString: urlString, success: { responseDictionary in
            print("rhe01 success 3 \(responseDictionary)")
            exp.fulfill()
            XCTAssert(!responseDictionary.isEmpty)

        }, failure: { error in
            print("rhe01 fail 3 \(error)")
            var isCorrectError = false
            if case MHError.tooManyRedirects = error {
                isCorrectError = true
            }
            exp.fulfill()
            XCTAssertFalse(!isCorrectError, "rhe01 test3 error \(error.errorDescription) : \(isCorrectError)")
        }, redirectLimit: numberOfRedirectsAllowed)

        waitForExpectations(timeout: 5, handler: nil)
    }
    func test1() {
        // We expect a circular reference error
        // we force this by adding the keyword to the end of the url
        // This is not really a very good test , would be better If we had a server with a circular reference

        print("test1")
        let numberOfRedirectsAllowed = 7
        let exp = self.expectation(description: "highExpectation")
        let urlString = "5e0af46b3300007e1120a7ef" + MHConstants.circularRedirectKeyword
        MHNetworkManager().getRequest(urlString: urlString, success: { responseDictionary in
            print("rhe01 success 1 \(responseDictionary)")
            exp.fulfill()
            XCTAssert(!responseDictionary.isEmpty)

        }, failure: { error in
            print("rhe01 fail 1 \(error)")
            var isCorrectError = false
            if case MHError.circularRedirect = error {
                isCorrectError = true
            }
            exp.fulfill()
            XCTAssertTrue(isCorrectError, "rhe01 test1 error \(error.errorDescription) : \(isCorrectError)")
        }, redirectLimit: numberOfRedirectsAllowed)

        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    static var allTests = [
        ("test1", test2),
        ("test2", test2),
        ("test3", test3),
        
    ]
}
