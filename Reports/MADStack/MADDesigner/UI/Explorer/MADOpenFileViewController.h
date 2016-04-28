//
//  MADOpenFileViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADOpenFileViewController_h
#define Reports_MADOpenFileViewController_h

#import <MADExplorer/MADFileExplorerViewController.h>

@protocol MADOpenFileViewControllerDelegate <NSObject>

    - (void)openDocumentAtURL:(NSURL *)url;
    - (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType;
    - (NSArray *)supportedUTIs;

@end

@interface MADOpenFileViewController : MADFileExplorerViewController

    @property (nonatomic, weak) id <MADOpenFileViewControllerDelegate> openFileDelegate;

    - (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                                 animated:(BOOL)animated;


    - (IBAction)done:(id)sender;
    - (IBAction)edit:(id)sender;

    - (void)getUserCloudPrefs;
    - (void)reenable;

@end

#endif
