//
//  MADocumentState.h
//  MAD
//
//  Created by Michael Thomason on 5/27/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADocumentState_h
#define Reports_MADocumentState_h

#import <Foundation/NSObject.h>

@interface MADocumentState : NSObject

    @property (nonatomic, assign, readwrite, getter = isSuspended) bool suspended;
    @property (nonatomic, assign, readwrite) bool saveInProgress;
    @property (nonatomic, assign, readwrite) bool saveInProgressLock;
    @property (nonatomic, assign, readwrite) bool needsSave;
    @property (nonatomic, assign, readwrite) bool contextChagned;

@end

#endif
