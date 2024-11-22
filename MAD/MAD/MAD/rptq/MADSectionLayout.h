//
//  MADSectionLayout.h
//  MAD
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADSectionLayout_h
#define MAD_MADSectionLayout_h

#import <objc/NSObject.h>
#import "MADocumentSectionType.h"
#import "RptqDocumentSectionWrappingStyle.h"

@class NSManagedObjectID, NSManagedObjectContext, NSNumber, NSDictionary;

@interface MADSectionLayout : NSObject

	@property (nonatomic, assign) int64_t identifier;
	@property (nonatomic, assign) MADDocumentSectionType type;
	@property (nonatomic, assign) float height;
	@property (nonatomic, assign) float displayHeight;
	@property (nonatomic, assign) NSUInteger groupLevel;
	@property (nonatomic, assign) NSUInteger numberOfRows;
	@property (nonatomic, assign, getter=isVisible) BOOL visibility;
	@property (nonatomic, assign) RptqDocumentSectionWrappingStyle wrappingStyle;
	@property (nonatomic, assign, readonly) BOOL producesFormFeed;
	@property (nonatomic, copy) NSManagedObjectID *objectID;
	@property (nonatomic, copy) NSNumber *identifierObject;

	- (instancetype)initWithObject:(NSDictionary *)object
			  managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

	- (NSString *)localizedDisplay;

@end

#endif
