//
//  Copyright (C) DB Systel GmbH.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

import XCTest
import DBNetworkStackSourcing
import DBNetworkStack
import Sourcing

extension Resource {
    static func mockWith(result: Model) -> Resource<Model> {
        let url: URL! = URL(string: "bahn.de")
        let request = URLRequest(url: url)
        
        return Resource(request: request, parse: { _ in return result })
    }
}

class ResourceDataProviderTests: XCTestCase {
    var resourceDataProvider: ResourceDataProvider<String>!
    var networkService: NetworkServiceMock!
    
    var didUpdateContents = false
    var notifiedDataSourceToProcess = false
    
    override func setUp() {
        super.setUp()
        
        networkService = NetworkServiceMock()
        
        resourceDataProvider = ResourceDataProvider(networkService: networkService, whenStateChanges: { _ in })
        resourceDataProvider.dataProviderDidUpdate = { [weak self] _ in
            self?.didUpdateContents = true
            self?.notifiedDataSourceToProcess = true
        }
        didUpdateContents = false
        notifiedDataSourceToProcess = false
        XCTAssert(resourceDataProvider.state.isEmpty)
    }
    
    func testInitEmpty() {
        
        //When
        let resourceDataProvider = ResourceDataProvider<Int>(networkService: networkService, whenStateChanges: { _ in })
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testInitWithResource() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        
        //When
        let resourceDataProvider = ResourceDataProvider(resource: resource, networkService: networkService, whenStateChanges: { _ in })
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testReconfigureResource() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        resourceDataProvider.load()
        
        //Then
        XCTAssert(resourceDataProvider.state.isLoading)
        XCTAssertEqual(networkService.requestCount, 1)
    }
    
    func testLoadTransformedResource() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        
        //When
        let resourceDataProvider = ResourceDataProvider(resource: resource, networkService: networkService, whenStateChanges: { _ in })
        resourceDataProvider.load()
        networkService.returnSuccess()
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssertEqual(networkService.requestCount, 1)
        XCTAssertEqual("Result", resourceDataProvider.contents.first?.first)
    }
    
    func testClear() {
        //When
        resourceDataProvider.clear()
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testLoadResource_skipLoadingState() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        resourceDataProvider.load(skipLoadingState: true)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 1)
    }
    
    func testLoadSucceed() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        resourceDataProvider.reconfigure(with: resource)
        
        //When
        resourceDataProvider.load()
        networkService.returnSuccess()
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssertEqual("Result", resourceDataProvider.contents.first?.first)
        XCTAssert(notifiedDataSourceToProcess)
        XCTAssert(didUpdateContents)
    }
    
    func testLoadError() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        resourceDataProvider.reconfigure(with: resource)
        
        //When
        
        resourceDataProvider.load()
        networkService.returnError(with: .unknownError)
        
        //Then
        XCTAssert(resourceDataProvider.state.hasError)
        XCTAssert(!didUpdateContents)
    }
    
    func testOnNetworkRequestCanceldWithEmptyData() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        resourceDataProvider.reconfigure(with: resource)
        
        //When
        resourceDataProvider.load()
        networkService.returnError(with: .cancelled)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 1)
    }
    
}
