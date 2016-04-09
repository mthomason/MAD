//
//  MADRefreshOperationInitalizeMainDataTable.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperationInitalizeMainDataTable.h"
#import <MAD/MADocument.h>
#import <MAD/MTDataTableFast.h>
#import <MAD/MTDataTable+Factory.h>

@interface MADRefreshOperationInitalizeMainDataTable ()

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, assign) bool success;

@end

@implementation MADRefreshOperationInitalizeMainDataTable

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithDocument:(MADocument *)document {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    if (self = [super init]) {
        _document = document;
        _success = false;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    MADocument *document = self.document;
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypePhysical);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSString *filename = document.filename;
    NSNumber *objectIdV =  @(filename.hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    
    MTDataTableFast *datatable = [MTDataTableFast newDataTableWithDefinition:parameters];
    datatable.cacheDelegate = document;
    [datatable loadFromCacheWithUrl:document.urlDataTableCache];
    document.mainDataTable = datatable;
    
    
    [self finish];
}

@end
