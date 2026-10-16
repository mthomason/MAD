//
//  RptqDocumentElementImage+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDocumentElementImage+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>

#if __APPLE__
#import <UIKit/UIImage.h>
#endif

#import "RptqDocument.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDataHelper.h"

@implementation RptqDocumentElementImage (Extras)

#pragma mark - Overrides

#if __APPLE__

// The store's Blob column holds PNG bytes -- what the legacy converter writes
// (MADStorePNGData) and what MADPngImageTransformer produced before it -- while the
// declared property is a UIImage.  The accessors are where the two forms meet, so a
// picture set here survives the save and reads back as a picture.  Apple only:
// UIImage is UIKit's, and nothing builds an image element off Apple.

- (UIImage *)image {
	id value = [self valueForUndefinedKey:@"image"];
	if ([value isKindOfClass:[NSData class]]) return [UIImage imageWithData:value];
	return [value isKindOfClass:[UIImage class]] ? value : nil;
}

- (void)setImage:(UIImage *)image {
	// The attribute is optional, so an image with no representation clears the column.
	[self setValue:(image ? UIImagePNGRepresentation(image) : nil) forUndefinedKey:@"image"];
}

#endif

- (NSString *)designerRepresentationText {
	return @"image";
}

#pragma mark - RptqDocumentElementFactory

+ (instancetype)getElementForObjectID:(int64_t)objectId
					fromObjectContext:(RptqStoreContext *)managedObjectContext {
	RptqObject *result = [managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:objectId];
	return (RptqDocumentElementImage *)result;
}

- (id)debugQuickLookObject {
	return self.image;
}

@end
