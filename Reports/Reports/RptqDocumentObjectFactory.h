//
//  RptqDocumentObjectFactory.h
//  Reports
//
//  Created by Michael Thomason on 3/6/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectFactory_h
#define Reports_RptqDocumentObjectFactory_h

@protocol RptqDocumentObjectFactory <NSObject>

@required

+ (id)getElementForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (RptqDocumentObject *)addDocumentObject:(id)object toDocument:(RptqDocument *)document;

@optional

@end

#endif
