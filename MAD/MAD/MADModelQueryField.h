//
//  MADModelQueryField.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADModelQueryField_h
#define MAD_MADModelQueryField_h

#import <MAD/MADModel.h>

@interface MADModelQueryField : MADModel
    <MADModelIDProtocol>
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                         schemaField:(NSManagedObjectID *)schemaField
               schemaFieldIdentifier:(int64_t)schemaFieldIdentifier;

@end

#endif /* MADModelQueryField_h */
