//
//  MADOpenFileViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADOpenFileViewController_h
#define Reports_MADOpenFileViewController_h

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MADCocoaExtensions/UIDocument+thumbnailURL.h>
#import <MADExplorer/MADFileExplorerViewController.h>
#import <MADExplorer/MTCollectionViewCellDocument.h>
#import <MADExplorer/MADFileLocationManager.h>
#import <MADExplorer/MADOpenDocumentManager.h>
#import <MADDataStructures/MTPair.h>
#import <MADFoundation/NSURL+Document.h>

@protocol MADOpenFileViewControllerDelegate <NSObject>

- (UIManagedDocument *)documentForURL:(NSURL *)url;
- (void)openDocumentAtURL:(NSURL *)url completionHandler:(void(^)(BOOL success, UIManagedDocument *document))handler;
- (void)didOpenDocument:(UIManagedDocument *)document;
- (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType;
- (NSArray *)supportedUTIs;

@end

@interface MADOpenFileViewController : MADFileExplorerViewController

@property (nonatomic, weak) id <MADOpenFileViewControllerDelegate> openFileDelegate;

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                             animated:(BOOL)animated;


- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

- (void)closeDocument:(UITraitCollection *)traitCollectionForThumbnail completion:(void (^)(BOOL))completion;
- (void)getUserCloudPrefs;
- (void)reenable;

@end

#endif
