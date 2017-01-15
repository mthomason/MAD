//
//  MADRefreshReloadOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADRefreshReloadOperation_h
#define MAD_Designer_MADRefreshReloadOperation_h

#import "MADGroupOperation.h"

@class UIViewController;
@class MADocument, MADDatabaseConnection;

@interface MADOperationRefreshReload : MADGroupOperation

    @property (readonly) BOOL completedSuccessfully;
    @property (nonatomic, readonly, weak) MADocument *document;

    - (instancetype)initWithDocument: (MADocument *)document
                      viewController: (UIViewController *)viewController
                  databaseConnection: (MADDatabaseConnection *)databaseConnection;

@end

#endif
