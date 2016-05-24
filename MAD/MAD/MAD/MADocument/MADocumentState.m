//
//  MADocumentState.m
//  MAD
//
//  Created by Michael Thomason on 5/27/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADocumentState.h"

@implementation MADocumentState

- (instancetype)init {
    if (self = [super init]) {
        self.saveInProgress = false;
        self.needsSave = false;
        self.contextChagned = false;
    }
    return self;
}

@end
