//
//  MADDocumentObjectDataReferenceImage.m
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectDataReferenceImage.h"
#import "RptqDocumentElementImage.h"

@interface MADDocumentObjectDataReferenceImage ()

@property (nonatomic, readonly) RptqDocumentElementImage *item;

@end

@implementation MADDocumentObjectDataReferenceImage

@dynamic item;
@dynamic image;

- (UIImage *)image {
	return self.item.image;
}

@end
