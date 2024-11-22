//
//  MADSectionGroupLayout.h
//  MAD
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADSectionGroupLayout_h
#define MAD_MADSectionGroupLayout_h

#import <MADSectionLayout.h>
#import <MADSortOrder.h>

@class NSSortDescriptor;

@interface MADSectionGroupLayout : MADSectionLayout

	@property (nonatomic, assign) MADSortOrder sort;
	@property (nonatomic, assign) int16_t weight;
	@property (nonatomic, assign) int16_t dataType;
	@property (nonatomic, copy) NSString * (^safeIdentifier)(NSString *);

	- (instancetype)initWithObject:(NSDictionary *)object
			  managedObjectContext:(NSManagedObjectContext *)managedObjectContext
					safeIdentifier:(NSString * (^)(NSString *))safeIdentifier;

	- (NSSortDescriptor *)sortDescriptor;

@end

#endif
