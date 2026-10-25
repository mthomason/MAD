//
//  MADRefreshOperationReload.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/3/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADRefreshOperationReload_h
#define MAD_Designer_MADRefreshOperationReload_h

#import <MADFoundation/MADOperation.h>

@class NSObject, MADocument;

@protocol MADOperationRefreshReloadProtocol;

@interface MADRefreshOperationReload : MADOperation

- (instancetype)initWithDocument: (MADocument *)document
				  viewController: (NSObject <MADOperationRefreshReloadProtocol> *)viewController;

@end

#endif
