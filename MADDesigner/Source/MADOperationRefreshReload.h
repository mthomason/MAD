//
//  MADOperationRefreshReload.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADRefreshReloadOperation_h
#define MAD_Designer_MADRefreshReloadOperation_h

#import <MADFoundation/MADGroupOperation.h>

@class UIViewController, MADocument, MADDatabaseConnection;
@protocol MADOperationRefreshReloadProtocol;

@interface MADOperationRefreshReload : MADGroupOperation

@property (readonly) BOOL completedSuccessfully;
@property (nonatomic, readonly, weak) MADocument *document;

- (instancetype)initWithDocument: (MADocument *)document
				  viewController: (UIViewController <MADOperationRefreshReloadProtocol> *)viewController
			  databaseConnection: (MADDatabaseConnection *)databaseConnection;

@end

#endif
