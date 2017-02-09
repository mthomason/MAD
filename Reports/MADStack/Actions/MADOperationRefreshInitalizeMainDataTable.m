//
//  MADRefreshOperationInitializeMainDataTable.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationRefreshInitalizeMainDataTable.h"
#import <MAD/MADocument.h>
#import <MAD/MADDataTableFast.h>
#import <MAD/MADDataTable.h>

@interface MADOperationRefreshInitializeMainDataTable ()

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, assign) BOOL success;

@end

@implementation MADOperationRefreshInitializeMainDataTable

- (void)dealloc {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithDocument:(MADocument *)document {
    if (self = [super init]) {
        _document = document;
        _success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    [self.document resetCache];
    
    [self finish];
}

@end
