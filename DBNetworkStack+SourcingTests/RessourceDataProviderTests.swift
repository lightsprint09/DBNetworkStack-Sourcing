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

class ResourceDataProviderDelagteMock: ResourceDataProviderDelagte {
    var state: ResourceDataProviderState?
    
    func resourceDataProviderDidChangeState(newState: ResourceDataProviderState) {
        state = newState
    }
}

class ResourceDataProviderTests: XCTestCase {
    var resourceDataProvider: ResourceDataProvider<String>!
    var networkService: NetworkServiceMock!
    
    var notifiedDataSourceToProcess = false
    var resourceDataProviderDelagteMock: ResourceDataProviderDelagteMock!
    
    override func setUp() {
        super.setUp()
        
        networkService = NetworkServiceMock()
        
        resourceDataProviderDelagteMock = ResourceDataProviderDelagteMock()
        resourceDataProvider = ResourceDataProvider(networkService: networkService, delegate: resourceDataProviderDelagteMock)
        
        resourceDataProvider.observable.addObserver { [weak self] _ in
            self?.notifiedDataSourceToProcess = true
        }
        notifiedDataSourceToProcess = false
        XCTAssert(resourceDataProvider.state.isEmpty)
    }
    
    func testInitEmpty() {
        //When
        let resourceDataProvider = ResourceDataProvider<Int>(networkService: networkService)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testInitWithResource() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        
        //When
        let resourceDataProvider = ResourceDataProvider(resource: resource, networkService: networkService)
        
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
        XCTAssert(resourceDataProviderDelagteMock.state?.isLoading ?? false)
        XCTAssert(!notifiedDataSourceToProcess)
        XCTAssertEqual(networkService.requestCount, 1)
    }
    
    func testLoadResource() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        
        //When
        let resourceDataProvider = ResourceDataProvider(resource: resource, networkService: networkService, delegate: resourceDataProviderDelagteMock)
        resourceDataProvider.load()
        networkService.returnSuccess()
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssert(resourceDataProviderDelagteMock.state?.hasSucceded ?? false)
        XCTAssertEqual(networkService.requestCount, 1)
        XCTAssertEqual("Result", resourceDataProvider.content.first?.first)
    }
    
    func testReconfigureSucceed() {
        //Given
        let resource = Resource.mockWith(result: ["Result"])
        resourceDataProvider.reconfigure(with: resource)
        
        //When
        resourceDataProvider.load()
        networkService.returnSuccess()
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssert(resourceDataProviderDelagteMock.state?.hasSucceded ?? false)
        XCTAssertEqual("Result", resourceDataProvider.content.first?.first)
        XCTAssert(notifiedDataSourceToProcess)
    }
    
    func testClear() {
        //When
        resourceDataProvider.clear()
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssert(resourceDataProviderDelagteMock.state?.isEmpty ?? false)
        XCTAssert(notifiedDataSourceToProcess)
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
        XCTAssertNil(resourceDataProviderDelagteMock.state)
        XCTAssertEqual(networkService.requestCount, 1)
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
        XCTAssert(!notifiedDataSourceToProcess)
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
