//
//  MADFeature.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFeature.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSSet.h>

@interface MADFeature ()

@property (nonatomic, copy, readwrite) NSString *productID;
@property (nonatomic, copy, readwrite) NSString *appleID;
@property (nonatomic, copy, readwrite) NSString *defaultTitle;
@property (nonatomic, copy, readwrite) NSString *defaultDescription;
@property (nonatomic, readwrite) MADFeatureType type;
@property (nonatomic, readwrite) BOOL available;

@end

@implementation MADFeature

- (instancetype)initWithProductID:(NSString *)productID
						  appleID:(NSString *)appleID
							title:(NSString *)title
					  description:(NSString *)description
							 type:(MADFeatureType)type
						available:(BOOL)available {
	self = [super init];
	if (self) {
		_productID = [productID copy];
		_appleID = [appleID copy];
		_defaultTitle = [title copy];
		_defaultDescription = [description copy];
		_type = type;
		_available = available;
	}
	return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary __deprecated_msg("Use initWithProductID:appleID:title:description:type:available: instead.") {
	NSString *productID = dictionary[@"product-id"];
	NSString *appleID = dictionary[@"apple-id"];
	NSString *title = dictionary[@"title"];
	NSString *description = dictionary[@"description"];
	// Read defensively. The entries used to be cast to NSNumber unconditionally, so a
	// plist value of the wrong shape (a string, say) sent -shortValue to an NSString and
	// crashed. A missing or non-numeric entry still reads as type 0, which is not one of
	// the declared MADFeatureType values -- documented, not changed; this initialiser is
	// deprecated in favour of the designated one.
	id typeValue = dictionary[@"type"];
	id availableValue = dictionary[@"available"];
	MADFeatureType type = [typeValue isKindOfClass:[NSNumber class]] ? (MADFeatureType)[typeValue shortValue] : (MADFeatureType)0;
	BOOL available = [availableValue isKindOfClass:[NSNumber class]] ? [availableValue boolValue] : NO;
	
	return [self initWithProductID:productID appleID:appleID title:title description:description type:type available:available];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.productID forKey:NSStringFromSelector(@selector(productID))];
	[coder encodeObject:self.appleID forKey:NSStringFromSelector(@selector(appleID))];
	[coder encodeObject:self.defaultTitle forKey:NSStringFromSelector(@selector(defaultTitle))];
	[coder encodeObject:self.defaultDescription forKey:NSStringFromSelector(@selector(defaultDescription))];
	[coder encodeInteger:self.type forKey:NSStringFromSelector(@selector(type))];
	[coder encodeBool:self.available forKey:NSStringFromSelector(@selector(available))];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	NSSet *stringClasses = [NSSet setWithObject:[NSString class]];
	
	NSString *productID = [coder decodeObjectOfClasses:stringClasses forKey:NSStringFromSelector(@selector(productID))];
	NSString *appleID = [coder decodeObjectOfClasses:stringClasses forKey:NSStringFromSelector(@selector(appleID))];
	NSString *title = [coder decodeObjectOfClasses:stringClasses forKey:NSStringFromSelector(@selector(defaultTitle))];
	NSString *description = [coder decodeObjectOfClasses:stringClasses forKey:NSStringFromSelector(@selector(defaultDescription))];

	MADFeatureType type = (MADFeatureType)[coder decodeIntegerForKey:NSStringFromSelector(@selector(type))];
	BOOL available = [coder decodeBoolForKey:NSStringFromSelector(@selector(available))];
	
	return [self initWithProductID:productID appleID:appleID title:title description:description type:type available:available];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	MADFeature *copy = [[[self class] allocWithZone:zone] initWithProductID:self.productID
																	appleID:self.appleID
																	  title:self.defaultTitle
																description:self.defaultDescription
																	   type:self.type
																  available:self.available];
	return copy;
}

@end
