//
//  MADDocumentCreationManagerInterface.h
//  MAD Designer
//
//  Created by Michael on 9/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDocumentCreationManagerInterface_h
#define MADDocumentCreationManagerInterface_h

@protocol MADDocumentCreationManagerProtocol;
@class MADDatabaseConnection, UIViewController;

@protocol MADDocumentCreationManagerInterface <NSObject>
    - (instancetype)initWithFilename: (NSString *)filename
                            delegate: (NSObject <MADDocumentCreationManagerProtocol> *)delegate
                  documentsDirectory: (NSURL *)documentsDirectory
                  databaseConnection: (MADDatabaseConnection *)databaseConnection
                      viewController: (UIViewController *)viewController;

    - (void)start;
@end

#endif /* MADDocumentCreationManagerInterface_h */
