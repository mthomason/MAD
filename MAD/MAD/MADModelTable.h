//
//  MADModelTable.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADModelTable_h
#define MADModelTable_h

#import <MAD/MADModel.h>

@class NSOrderedSet, MADModelField;

@interface MADModelTable : MADModel
    <MADModelIDProtocol>
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                                name:(NSString *)name;
    @property (nonatomic, readonly, strong)     NSString *name;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelField *> *fields;
    - (void)addFieldWithID:(NSManagedObjectID *)objectID
                identifier:(int64_t)identifier
                      name:(NSString *)name
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

#endif /* MADModelTable_h */
