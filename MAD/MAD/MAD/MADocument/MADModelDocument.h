//
//  MADModelDocument.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADModelDocument_h
#define MADModelDocument_h

#import <MAD/MADModel.h>
#import <MAD/MADModelDataProtocol.h>

@class MADModelDatabase, MADModelQuery, NSOrderedSet<__covariant ObjectType>;

@interface MADModelDocument : MADModel
    <MADModelIDProtocol, MADModelDataProtocol>

    - (instancetype)initWithContext:(NSManagedObjectContext *)managedObjectContext;

    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelDatabase *> *databases;
    @property (nonatomic, readonly, weak)       MADModelDatabase *firstDatabase;
    @property (nonatomic, readonly, weak)       MADModelQuery *firstQuery;

@end

#endif /* MADModelDocument_h */
