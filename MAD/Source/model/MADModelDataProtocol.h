//
//  MADModelDataProtocol.h
//  MAD
//
//  Created by Michael on 6/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The read-model's data protocol: a store context, an id+context initializer, and
//  -update, the refresh hook the layer's own lazy getters call.  Nothing outside
//  the layer calls -update (docs/project/MADModel_Layer.md §2.8).
//

#ifndef MADModelDataProtocol_h
#define MADModelDataProtocol_h


@protocol MADModelDataProtocol <NSObject>

@property (nonatomic, readonly, weak) RptqStoreContext *managedObjectContext;

- (instancetype)initWithIdentifier:(int64_t)identifier managedObjectContext:(RptqStoreContext *)managedObjectContext;
- (void)update;

@end

#endif /* MADModelDataProtocol_h */
