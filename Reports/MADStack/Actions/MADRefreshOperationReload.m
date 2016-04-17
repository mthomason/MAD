//
//  MADRefreshOperationReload.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/3/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperationReload.h"
#import <MAD/MADocument.h>
#import <MAD/MTPaper.h>
#import "MADPageViewAttributes.h"

@interface MADRefreshOperationReload ()

    @property (nonatomic, readwrite, weak) MADocument *document;
    @property (nonatomic, readwrite, copy) MADPageViewAttributes *pageAttributes;
    @property (nonatomic, readwrite, assign) bool success;

@end

@implementation MADRefreshOperationReload

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

    MADocument *document = self.document;
    [document prepareForQuery];
    document.reportFormatter.didRefresh = YES;
    [document.reportFormatter formatForSize: document.paper.paperSize contentChanged: YES];
    
    MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
    pageAttributes.pageNumber = 0;
    pageAttributes.numberOfPages = document.reportFormatter.numberOfPages;
    pageAttributes.contentSizeInital = document.paper.paperSize;
    pageAttributes.zoomScaleInital = 1.0;
    pageAttributes.contentScaleFactor = 0.0;

    [self finish];
}

@end
