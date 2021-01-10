//
//  Matrix_Interview_MainAsyncTests.swift
//  Matrix_Interview_MainTests
//
//  Created by hyperactive on 07/01/2021.
//

import XCTest
@testable import Matrix_Interview_Main

class Matrix_Interview_MainAsyncTests: XCTestCase {

    var session: URLSession!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        session = URLSession(configuration: .default)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        session = nil
        super.tearDown()
    }

    func test_CallToRestCountries_Completes() {
        
        //given
        let url = URL(string: Constants.url)
        let promise = expectation(description: "Completion handler invoked")
        var statusCode: Int?
        var responseError: Error?
        
        //when
        let dataTask = session.dataTask(with: url!) { (data, response, error) in
            
            statusCode = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            promise.fulfill()
        }
        
        dataTask.resume()
        wait(for: [promise], timeout: 5)
        
        //then
        XCTAssertNil(responseError, "Had Some Error In Response")
        XCTAssertEqual(statusCode, 200, "Bad Status Code, download failed due to code \(String(describing: statusCode))")
    }
    
    func test_MakeEmptyCountryWithDataManager_ShouldBeEqual() {
        
        //given
        let country = Country(name: "", nativeName: "", area: 0, alphaCode: "", borders: [])
        
        //when
        let testCountry = DataManager.shared.makeCountry(from: NSDictionary(dictionary: ["name": "", "nativeName": "", "area" : 0, "alpha3Code" : "", "borders" : []]))
        
        //then
        XCTAssert(country == testCountry)
    }
}
