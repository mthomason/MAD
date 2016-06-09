//
//  MADDocumentCachedDataReference.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTDatabase;
@class MTDataTableFast;
@class RptqQueryField;

@interface MADDocumentCachedDataReference : NSObject

    - (instancetype)initWithTableName:(NSString *)tableName
                            fieldName:(NSString *)fieldName
                                rowID:(NSUInteger)rowID;

    - (instancetype)initWithDatabase:(MTDatabase *)database
                referencesQueryField:(RptqQueryField *)referencesQueryField
                               rowID:(NSUInteger)rowID;

@end
