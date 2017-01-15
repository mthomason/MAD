//
//  MADOperationCreateDocument.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADCreateDocumentOperation_h
#define MAD_Designer_MADCreateDocumentOperation_h

#import "MADGroupOperation.h"

@class UIViewController, MADDatabaseConnection;

@interface MADOperationCreateDocument : MADGroupOperation

    - (instancetype)initWithFilename: (NSString *)filename documentsDirectory:(NSURL *)documentsDirectory
                  databaseConnection: (MADDatabaseConnection *)databaseConnection
                      viewController: (UIViewController *)viewController;

@end

#endif
