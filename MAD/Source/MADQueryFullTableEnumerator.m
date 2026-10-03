//
//  MADQueryFullTableEnumerator.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryFullTableEnumerator.h"
#import <MAD/RptqStoreContext.h>
#import "RptqDocument.h"
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

@interface MADQueryFullTableEnumerator ()

@property (nonatomic, strong) RptqStoreContext *managedObjectContext;
@property (nonatomic, assign) int64_t documentObjectIdentifier;

@end

@implementation MADQueryFullTableEnumerator

- (instancetype)initWithDocument:(RptqDocument *)document {
	if (self = [super init]) {
		_documentObjectIdentifier = document.identifier;
		self.managedObjectContext = document.storeContext;
		
	}
	return self;
}

@end
