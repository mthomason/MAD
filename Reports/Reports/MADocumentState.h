//
//  MADocumentState.h
//  MAD
//
//  Created by Michael Thomason on 5/27/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADocumentState : NSObject

@property (nonatomic, assign, readwrite) BOOL saveInProgress;
@property (nonatomic, assign, readwrite) BOOL saveInProgressLock;
@property (nonatomic, assign, readwrite) BOOL needsSave;
@property (nonatomic, assign, readwrite) BOOL contextChagned;

@end
