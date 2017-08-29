//
//  MADRefreshOperationInitializeMainDataTable.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationRefreshInitalizeMainDataTable.h"
#import <MADFoundation/MADDataTable.h>
#import <MAD/MADocument.h>
#import <MAD/MADDataTableFast.h>

@interface MADOperationRefreshInitializeMainDataTable ()

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, assign) BOOL success;

@end

@implementation MADOperationRefreshInitializeMainDataTable

- (instancetype)initWithDocument:(MADocument *)document {
    if (self = [super init]) {
        _document = document;
        _success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    if (self.cancelled) {
        return [self finish];
    }

    [self.document resetCache];
    
    [self finish];
}

@end
