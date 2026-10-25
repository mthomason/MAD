//
//  MADDocumentCreationManagerInterface.h
//  MAD Designer
//
//  Created by Michael on 9/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDocumentCreationManagerInterface_h
#define MADDocumentCreationManagerInterface_h

#import <Foundation/NSObject.h>

@protocol MADDocumentCreationManagerProtocol;

@class MADDatabaseConnection, UIViewController, NSString, NSURL;

@protocol MADDocumentCreationManagerInterface <NSObject>
	- (instancetype)initWithFilename: (NSString *)filename
							delegate: (NSObject <MADDocumentCreationManagerProtocol> *)delegate
				  documentsDirectory: (NSURL *)documentsDirectory
				  databaseConnection: (MADDatabaseConnection *)databaseConnection
					  viewController: (UIViewController *)viewController;

	- (void)start;
@end

#endif /* MADDocumentCreationManagerInterface_h */
