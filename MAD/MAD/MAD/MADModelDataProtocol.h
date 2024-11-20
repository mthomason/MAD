//
//  MADModelDataProtocol.h
//  MAD
//
//  Created by Michael on 6/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADModelDataProtocol_h
#define MADModelDataProtocol_h

@class NSManagedObjectContext;

@protocol MADModelDataProtocol <NSObject>

    - (instancetype)initWithIdentifier:(int64_t)identifier
                  managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    @property (nonatomic, readonly, weak)      NSManagedObjectContext *managedObjectContext;

    - (void)update;

@end

#endif /* MADModelDataProtocol_h */
