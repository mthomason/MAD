//
//  MADOperationCreateDocument.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADCreateDocumentOperation_h
#define MAD_Designer_MADCreateDocumentOperation_h

#import <MADFoundation/MADGroupOperation.h>

@class UIViewController, MADDatabaseConnection;

@interface MADOperationCreateDocument : MADGroupOperation

	- (instancetype)initWithFilename: (NSString *)filename
				  documentsDirectory: (NSURL *)documentsDirectory
				  databaseConnection: (MADDatabaseConnection *)databaseConnection
					  viewController: (UIViewController *)viewController;

	@property (nonatomic, assign, readonly, getter=isSuccessConnection) BOOL connectionSuccess;
	@property (nonatomic, assign, readonly, getter=isSuccessCreate) BOOL successCreate;

@end

#endif
