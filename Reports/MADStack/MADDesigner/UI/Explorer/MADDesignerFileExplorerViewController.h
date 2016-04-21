//
//  MADDesignerFileExplorerViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/21/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADDesignerFileExplorerViewController_h
#define MAD_Designer_MADDesignerFileExplorerViewController_h

#import "MADOpenFileViewController.h"

@interface MADDesignerFileExplorerViewController : MADOpenFileViewController
    <MADOpenFileViewControllerDelegate>

    - (void)openDocumentAtURL:(NSURL *)url
            completionHandler:(void(^)(BOOL success, UIManagedDocument *document))handler;

@end

#endif
