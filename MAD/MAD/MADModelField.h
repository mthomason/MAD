//
//  MADModelField.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADModelField_h
#define MADModelField_h

#import <MAD/MADModel.h>

@interface MADModelField : MADModel
    <MADModelIDProtocol>
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                                name:(NSString *)name;
@end

#endif /* MADModelField_h */
