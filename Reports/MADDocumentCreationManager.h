//
//  MADDocumentCreationManager.h
//  MAD Designer
//
//  Created by Michael on 9/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADDocumentCreationManager_h
#define MADDesigner_MADDocumentCreationManager_h

#import <Foundation/NSObject.h>

@class MADDocumentCreationManager, MADDatabaseConnection, UIViewController;

@protocol MADDocumentCreationManagerProtocol <NSObject>
    - (void)documentCreationManager:(MADDocumentCreationManager *)manager
                          didFinish:(BOOL)success;
@end

@interface MADDocumentCreationManager : NSObject

    - (instancetype)initWithFilename: (NSString *)filename
                            delegate: (NSObject <MADDocumentCreationManagerProtocol> *)delegate
                  documentsDirectory: (NSURL *)documentsDirectory
                  databaseConnection: (MADDatabaseConnection *)databaseConnection
                      viewController: (UIViewController *)viewController;

    - (void)start;

@end

#endif
