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
@class MADocument, MTDatabaseConnection;

@interface MADRefreshReloadOperation : MADGroupOperation

    @property (readonly) bool completedSuccessfully;
    @property (nonatomic, readonly, weak) MADocument *document;

    - (instancetype)initWithDocument: (MADocument *)document viewController:(UIViewController *)viewController
                  databaseConnection: (MTDatabaseConnection *)databaseConnection;

@end

#endif
