//
//  MADFeatures.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFeatures.h"
#import "MADFeature.h"
#import <MADFoundation/madlog.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSFileManager.h>

@interface MADFeatures ()

@property (nonatomic, strong, readwrite) NSArray <MADFeature *> *features;

@end

@implementation MADFeatures

- (instancetype)init {
	if (self = [super init]) {
		_features = @[];
	}
	return self;
}

- (BOOL)loadFeaturesFromPlist {
	// Get the path to the plist file in the main bundle
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MADFeatures" ofType:@"plist"];
	// Validate if the plist file exists
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		MADLogError("Error: Plist file not found at path: %@", path);
		return NO;
	}
	
	NSArray *rawFeatures = [NSArray arrayWithContentsOfFile:path];
	
	// Validate if the loaded data is an array and contains elements
	if (!rawFeatures || ![rawFeatures isKindOfClass:[NSArray class]] || rawFeatures.count == 0) {
		MADLogError("Error: Plist data is empty or not in expected array format.");
		return NO;
	}
	
	NSMutableArray <MADFeature *> *parsedFeatures = [[NSMutableArray alloc] initWithCapacity:rawFeatures.count];
	
	// Iterate through each dictionary in the rawFeatures array
	for (NSDictionary *dictionary in rawFeatures) {
		// Ensure the item is actually a dictionary before processing
		if (![dictionary isKindOfClass:[NSDictionary class]]) {
			MADLogError("Warning: Skipping non-dictionary item in plist: %@", dictionary);
			continue;
		}
		
		// Extract values using the defined dictionary keys
		// Perform type checking and provide default values or skip if essential data is missing
		NSString *productID = dictionary[@"product-id"];
		NSString *appleID = dictionary[@"apple-id"];
		NSString *title = dictionary[@"title"];
		NSString *description = dictionary[@"description"];
		NSNumber *typeNumber = ((NSNumber *)dictionary[@"type"]);
		NSNumber *availableNumber = ((NSNumber *)dictionary[@"available"]);

		// Basic validation for essential properties
		if (!productID || ![productID isKindOfClass:[NSString class]]) {
			MADLogError("Warning: Skipping feature due to missing or invalid productID in dictionary: %@", dictionary);
			continue;
		}
		if (!appleID || ![appleID isKindOfClass:[NSString class]]) {
			MADLogError("Warning: Skipping feature due to missing or invalid appleID in dictionary: %@", dictionary);
			continue;
		}
		if (!title || ![title isKindOfClass:[NSString class]]) {
			MADLogError("Warning: Skipping feature due to missing or invalid title in dictionary: %@", dictionary);
			continue;
		}
		if (!description || ![description isKindOfClass:[NSString class]]) {
			MADLogError("Warning: Skipping feature due to missing or invalid description in dictionary: %@", dictionary);
			continue;
		}
		if (!typeNumber || ![typeNumber isKindOfClass:[NSNumber class]]) {
			MADLogError("Warning: Skipping feature due to missing or invalid type in dictionary: %@", dictionary);
			continue;
		}
		if (!availableNumber || ![availableNumber isKindOfClass:[NSNumber class]]) {
			MADLogError("Warning: Skipping feature due to missing or invalid available status in dictionary: %@", dictionary);
			continue;
		}
		
		// Convert NSNumber to MADFeatureType (short) and BOOL
		MADFeatureType type = (MADFeatureType)[typeNumber shortValue];
		BOOL available = [availableNumber boolValue];
		
		// Create a MADFeature object using its designated initializer
		MADFeature *feature = [[MADFeature alloc] initWithProductID:productID
															appleID:appleID
															  title:title
														description:description
															   type:type
														  available:available];
		if (feature) { // Ensure feature object was successfully created
			[parsedFeatures addObject:feature];
		} else {
			MADLogError("Error: Failed to create MADFeature object from dictionary: %@", dictionary);
		}
	}
	
	// Assign the populated array to the features property
	self.features = parsedFeatures;
	
	// Return YES if any features were successfully loaded, NO otherwise
	return self.features.count > 0;
}

- (NSArray <MADFeature *> *)availableFeatures {
	NSPredicate *available = [NSPredicate predicateWithBlock:^BOOL(MADFeature *feature, NSDictionary *__unused bindings) {
		return feature.available;
	}];
	return [self.features filteredArrayUsingPredicate:available];
}

- (NSArray <NSString *> *)availableFeaturesProductIDs {
	NSArray *availableFeatures = [self availableFeatures];
	NSMutableArray <NSString *> *featureIDs = [[NSMutableArray alloc] initWithCapacity:self.availableFeatures.count];
	for (MADFeature *feature in availableFeatures) {
		[featureIDs addObject:feature.productID];
	}
	return featureIDs;
}

- (MADFeature *)featureForProductID:(NSString *)productID {
	NSPredicate *product = [NSPredicate predicateWithBlock:^BOOL(MADFeature *feature, NSDictionary *__unused bindings) {
		return [feature.productID isEqualToString:productID];
	}];
	return [[self.features filteredArrayUsingPredicate:product] firstObject];
}

@end
