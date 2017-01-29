//
//  RptqDataHelper.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqUserCredentals_MADDatabaseConnection_h
#define Reports_RptqUserCredentals_MADDatabaseConnection_h

#import <Foundation/NSObject.h>

@class NSManagedObjectContext;

@interface RptqDataHelper : NSObject

    + (NSNumber *)nextIdentifierForClass:(Class)class
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
