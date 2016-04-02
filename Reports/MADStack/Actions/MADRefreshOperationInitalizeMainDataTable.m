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

- (instancetype)initWithDocument:(MADocument *)document {
    if (self = [super init]) {
        _document = document;
        _success = false;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    MADocument *document = self.document;
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypePhysical);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(document.fileName.hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    
    MTDataTableFast *datatable = [MTDataTableFast dataTableFactory:parameters];
    datatable.cacheDelegate = document;
    NSString *filename = [datatable filenameMDCache];
    NSURL *cacheUrl = [document cacheUrlForFilename:filename].copy;
    document.urlDataTableCache = cacheUrl;
    [datatable loadFromCacheWithUrl:cacheUrl];
    document.mainDataTable = datatable;
    
    
    [self finish];
}

@end
