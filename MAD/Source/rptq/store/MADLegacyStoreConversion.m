//
//  MADLegacyStoreConversion.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "MADLegacyStoreConversion.h"

NSString * const MADLegacyStoreConversionErrorDomain = @"MADLegacyStoreConversionErrorDomain";

NSString * const MADLegacyStoreDirectory = @"StoreContent";
NSString * const MADLegacyStoreName = @"analyitics";

static id<MADDocumentLegacyStoreConverting> MADLegacyStoreConverter = nil;

@implementation MADLegacyStoreConversion

+ (void)setConverter:(id<MADDocumentLegacyStoreConverting>)converter {
	@synchronized (self) {
		MADLegacyStoreConverter = converter;
	}
}

+ (id<MADDocumentLegacyStoreConverting>)converter {
	@synchronized (self) {
		return MADLegacyStoreConverter;
	}
}

@end
