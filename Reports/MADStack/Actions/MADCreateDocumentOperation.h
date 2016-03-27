//
//  MADCreateDocumentOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADCreateDocumentOperation_h
#define MAD_Designer_MADCreateDocumentOperation_h

#import "MADGroupOperation.h"

@class UIViewController, MTDatabaseConnection;

@interface MADCreateDocumentOperation : MADGroupOperation

    - (instancetype)initWithFilename: (NSString *)filename documentsDirectory:(NSURL *)documentsDirectory
                  databaseConnection: (MTDatabaseConnection *)databaseConnection
                      viewController: (UIViewController *)viewController;

@end

#endif
