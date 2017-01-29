//
//  MADDocumentObjectImage.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectImage.h"
#import "RptqDocumentObjectImage+CoreDataClass.h"
#import "MADDocumentObjectCachedDataReferenceItem.h"
#import "MADDocumentObjectReference.h"
#import "RptqDocumentObject+CoreDataClass.h"
#import "RptqDocumentObjectImage+CoreDataProperties.h"
#import <UIKit/UIImage.h>

@interface MADDocumentObjectImage ()
    @property (nonatomic, weak) RptqDocumentObjectImage *item;
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
