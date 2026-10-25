//
//  MADStoreLegacyConverter.m
//  MAD Designer
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADStoreLegacyConverter.h"
#import "MADStoreConverter.h"

static NSString * const MADStoreLegacyModelName = @"MAD";
static NSString * const MADStoreLegacyModelExtension = @"momd";

@implementation MADStoreLegacyConverter

+ (void)load {
	[MADLegacyStoreConversion setConverter:[[MADStoreLegacyConverter alloc] init]];
}

- (BOOL)convertLegacyStoreAtURL:(NSURL *)legacyStoreURL
				  toStoreAtURL:(NSURL *)storeURL
						  error:(NSError * __autoreleasing *)error {
	NSManagedObjectModel *model = [self.class legacyModel];
	if (model == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:MADStoreConverterErrorDomain
										 code:MADStoreConverterErrorModelMissing
									 userInfo:@{ NSLocalizedDescriptionKey:
										[[NSString alloc] initWithFormat:@"The compiled %@.%@ is missing from every bundle this process can see.",
										 MADStoreLegacyModelName, MADStoreLegacyModelExtension] }];
		}
		return NO;
	}
	return [MADStoreConverter convertLegacyStoreAtURL:legacyStoreURL
										 toStoreAtURL:storeURL
												model:model
												error:error] != nil;
}

/// The compiled model the document was written against: the main bundle first (the
/// app bundle, or the directory the CLI binary lives in), then this class's bundle
/// (the test bundle, which compiles the model into itself).
+ (NSManagedObjectModel *)legacyModel {
	NSURL *url = [[NSBundle mainBundle] URLForResource:MADStoreLegacyModelName
										 withExtension:MADStoreLegacyModelExtension];
	if (url == nil) {
		url = [[NSBundle bundleForClass:[self class]] URLForResource:MADStoreLegacyModelName
													   withExtension:MADStoreLegacyModelExtension];
	}
	return url ? [[NSManagedObjectModel alloc] initWithContentsOfURL:url] : nil;
}

@end
