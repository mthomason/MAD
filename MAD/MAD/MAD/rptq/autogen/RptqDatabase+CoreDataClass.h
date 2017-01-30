//
//  RptqDatabase+CoreDataClass.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable, RptqDocument, RptqQuery, RptqUserCredentals;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabase : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqDatabase+CoreDataProperties.h"
