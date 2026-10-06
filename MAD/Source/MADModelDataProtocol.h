//
//  MADModelDataProtocol.h
//  MAD
//
//  Created by Michael on 6/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADModelDataProtocol_h
#define MADModelDataProtocol_h


@protocol MADModelDataProtocol <NSObject>

@property (nonatomic, readonly, weak) RptqStoreContext *managedObjectContext;

- (instancetype)initWithIdentifier:(int64_t)identifier managedObjectContext:(RptqStoreContext *)managedObjectContext;
- (void)update;

@end

#endif /* MADModelDataProtocol_h */
