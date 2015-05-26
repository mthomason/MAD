//
//  Test_Cloud.m
//  Test Cloud
//
//  Created by Michael Thomason on 9/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MACloudManager.h"

@interface Test_Cloud : XCTestCase

@end

@implementation Test_Cloud

- (void)setUp {

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver: [MACloudManager sharedManager]
                      selector: @selector(handleNotificationUbiquityIdentityDidChange:)
                          name: NSUbiquityIdentityDidChangeNotification
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationUpdateCloudEnabled:)
                          name: MADNotificationCloudStateUpdated
                        object: nil];
    
    
        [super setUp];
    
}

- (void)tearDown {
    [super tearDown];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver: [MACloudManager sharedManager]
                             name: NSUbiquityIdentityDidChangeNotification
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: MADNotificationCloudStateUpdated
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                           object: nil];

}

- (void)testExample {
    NSLog(@"%@", [MACloudManager sharedManager].ubiquitousDocumentsDirectory);
    //NSLog(@"%@", [MACloudManager sharedManager].isCloudEnabled ? @"YES" : @"NO");
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)handleNotificationWillBeginFetchingUbiquitousContainer:(NSNotification *)notification {
    // FIXME: Start timer, and display activity indictor if it takes too long
    //  to bring back a ubiquitous container.
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)handleNotificationDidEndFetchingUbiquitousContainer:(NSNotification *)notification {
    // FIXME: Remove activity indictor for ubiquitous container.
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)handleNotificationUpdateCloudEnabled:(NSNotification *)notification {
    // FIXME: Implement logic for cloud status enabled change.
    //  Pop to root view controller / file view controller.
    //  Reload file view controller, getting docs from new
    //  cloud container.
    
    NSLog(@"%s %@", __PRETTY_FUNCTION__, notification);
    
}


@end
