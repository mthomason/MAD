//
//  RptqDocumentObjectFactory.h
//  Reports
//
//  Created by Michael Thomason on 3/6/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectFactory_h
#define Reports_RptqDocumentObjectFactory_h

#import "RptqDocument.h"
#import "RptqDocumentObject.h"

@protocol RptqDocumentObjectFactory <NSObject>

@required

+ (id)documentObjectForObjectID:(NSManagedObjectID *)objectId managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@optional

@end

#endif
