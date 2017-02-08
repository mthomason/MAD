//
//  MADTableFieldIdentifier.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTableFieldIdentifier_h
#define MAD_MADTableFieldIdentifier_h

#import <Foundation/NSObject.h>

@class NSManagedObjectID;

@interface MADTableFieldReference : NSObject

- (instancetype)initWithTableID:(NSManagedObjectID *)tableID
                     andFieldID:(NSManagedObjectID *)fieldID NS_DESIGNATED_INITIALIZER;

    @property (readonly, nonatomic, copy) NSManagedObjectID *tableID;
    @property (readonly, nonatomic, copy) NSManagedObjectID *fieldID;

@end

@interface MADTableFieldIdentifier : NSObject

- (instancetype)initWithTableID:(int64_t)tableID
                     andFieldID:(int64_t)fieldID NS_DESIGNATED_INITIALIZER;

    @property (readonly, nonatomic, assign) int64_t tableID;
    @property (readonly, nonatomic, assign) int64_t fieldID;

    - (NSNumber *)tableObjectID;
    - (NSNumber *)fieldObjectID;

@end

#endif /* MADTableFieldIdentifier_h */
