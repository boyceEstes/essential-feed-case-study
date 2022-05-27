//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }

	
    func test_localFeedLoader_loadOnEmptyCache_deliversNoItems() {
        
        let sut = makeSUT()
        
        expect(sut, toLoad: [])
    }
    
    
    func test_localFeedLoader_saveOnSeparateInstance_deliversItems() {
        
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feed = uniqueImageFeed().models
        
        save(feed, with: sutToPerformSave)
        
        expect(sutToPerformLoad, toLoad: feed)
    }
    
    
    func test_localFeedLoader_itemsSavedOnSeparateInstance_overridesItems() {
        
        let sutToPerformFirstSave = makeSUT()
        let sutToPerformLastSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let firstFeed = uniqueImageFeed().models
        let latestFeed = uniqueImageFeed().models

        save(firstFeed, with: sutToPerformFirstSave)
        save(latestFeed, with: sutToPerformLastSave)
        
        expect(sutToPerformLoad, toLoad: latestFeed)
    }
    
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalFeedLoader {
        
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = specificTestStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        trackForMemoryLeaks(store)
        trackForMemoryLeaks(sut)
        return sut
    }
    
    
    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        
        
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { result in
            switch result {
                
            case let .success(imageFeed):
                XCTAssertEqual(imageFeed, expectedFeed)
            default:
                XCTFail("Expected successful feed result, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    
    private func save(_ feed: [FeedImage], with sut: LocalFeedLoader, file: StaticString = #file, line: UInt = #line) {
        
        let saveExp = expectation(description: "Wait for save completion")
        sut.save(feed) { saveError in
            XCTAssertNil(saveError)
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1)
    }
                               
    
    private func setupEmptyStoreState() {
        
        deleteStoreArtifacts()
    }
    
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: specificTestStoreURL())
    }


    private func specificTestStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }


    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
