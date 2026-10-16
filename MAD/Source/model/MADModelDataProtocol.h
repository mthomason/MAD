//
//  MADModelDataProtocol.h
//  MAD
//
//  Created by Michael on 6/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
//  The read-model's data protocol: a store context, an id+context initializer, and
//  -update, the refresh hook the layer's own lazy getters call.  Nothing outside
//  the layer calls -update (MADModel_Layer.md §2.8).
//

#ifndef MADModelDataProtocol_h
#define MADModelDataProtocol_h


@protocol MADModelDataProtocol <NSObject>

@property (nonatomic, readonly, weak) RptqStoreContext *managedObjectContext;

- (instancetype)initWithIdentifier:(int64_t)identifier managedObjectContext:(RptqStoreContext *)managedObjectContext;
- (void)update;

@end

#endif /* MADModelDataProtocol_h */
