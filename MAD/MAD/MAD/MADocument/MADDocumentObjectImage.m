//
//  MADDocumentObjectImage.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectImage.h"
#import "RptqDocumentObjectImage.h"
#import "MADDocumentObjectCachedDataReferenceItem.h"
#import "MADDocumentObjectReference.h"
#import "RptqDocumentObject.h"

@interface MADDocumentObjectImage ()
    @property (nonatomic, weak) RptqDocumentObject *item;
@end

@implementation MADDocumentObjectImage

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super init]) {
        self.item = definition.item;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [self.item.isImage.image drawInRect:rect];
}

@end
