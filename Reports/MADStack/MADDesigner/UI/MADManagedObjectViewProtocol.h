//
//  MADManagedObjectViewProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADManagedObjectViewProtocol_h
#define MAD_MADManagedObjectViewProtocol_h

#import <Foundation/NSObject.h>

@class NSManagedObjectID;

@protocol MADManagedObjectViewProtocol <NSObject>
  @required
	@property (nonatomic, assign) int64_t identifier;
	@property (readonly, nonatomic, copy) NSNumber *key;
  @optional
	@property (nonatomic, readonly, copy) NSManagedObjectID *objectID;
@end

#endif /* MADManagedObjectViewProtocol_h */
