//
//  MADModelDocument.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADModelDocument_h
#define MADModelDocument_h

#import <MAD/MADModel.h>

@interface MADModelDocument : MADObjectID
    <MADModelIDProtocol, MADModelDataProtocol>

    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelDatabase *> *databases;
    @property (nonatomic, readonly, weak)       MADModelDatabase *firstDatabase;
    @property (nonatomic, readonly, weak)       MADModelQuery *firstQuery;

@end

#endif /* MADModelDocument_h */
