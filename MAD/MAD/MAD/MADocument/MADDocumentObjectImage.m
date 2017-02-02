//
//  MADDocumentObjectImage.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectImage.h"
#import "RptqDocumentElementImage.h"
//#import "MADDocumentObjectCachedDataReferenceItem.h"
#import "MADDocumentObjectReference.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElementImage.h"
#import <UIKit/UIImage.h>

@interface MADDocumentObjectImage ()
    @property (nonatomic, weak) RptqDocumentElementImage *item;
@end

@implementation MADDocumentObjectImage

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super init]) {
        self.item = definition.item;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [(UIImage *)self.item.image drawInRect:rect];
}

@end
