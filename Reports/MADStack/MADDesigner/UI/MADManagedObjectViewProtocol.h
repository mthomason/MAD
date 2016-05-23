//
//  MADManagedObjectViewProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADManagedObjectViewProtocol_h
#define MADManagedObjectViewProtocol_h

@class NSManagedObjectID;

@protocol MADManagedObjectViewProtocol <NSObject>
@required;
    @property (nonatomic, copy) NSManagedObjectID *objectIdTag;
@end

#endif /* MADManagedObjectViewProtocol_h */
