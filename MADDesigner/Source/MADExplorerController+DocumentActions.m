//
//  MADExplorerController+DocumentActions.m
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADExplorerController+DocumentActions.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation MADExplorerController (DocumentActions)

#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController * __unused)controller {
	id interactionController = self.navigationController;
	return interactionController;
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController * __unused)controller
		  didFinishWithResult:(MFMailComposeResult __unused)result
						error:(NSError *)error {
	
	[NSError presentError: error onViewController: self completion:^(BOOL __unused success) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}];
}

#pragma mark -
#pragma mark UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> * __unused)urls {
	[controller removeFromParentViewController];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
	[controller removeFromParentViewController];
}

#pragma mark -
#pragma mark Actions

- (IBAction)actionAddDocument:(id __unused)sender {
	
	UINavigationController *navControl = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeNewDocument];
	[MADThemeManager applyAppearanceToNavigationController:navControl traitCollection:self.traitCollection];

	navControl.modalPresentationStyle = UIModalPresentationFormSheet;
	navControl.presentationController.delegate = self;
	
	MADDriverSelectorController *databaseDriverSelector = (MADDriverSelectorController *)navControl.topViewController;
	databaseDriverSelector.delegate = self;
	databaseDriverSelector.saveFileDelegate = self;
	
	self.definesPresentationContext = YES;
	self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	UIPresentationController *pc = navControl.presentationController;
	pc.presentedView.backgroundColor = [UIColor systemBackgroundColor];
	[self showViewController:navControl animated:YES];
}

- (IBAction)actionInformation:(id)sender {
	
	if (_aboutViewControllerOnScreen) {
		_aboutViewControllerOnScreen = NO;
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	if (_infoControllerOnScreen) {
		_infoControllerOnScreen = NO;
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
		_infoControllerOnScreen = YES;
		UINavigationController *infoViewController = [UINavigationController navigationControllerWithType:MADNavigationControllerTypeInformation];
		[MADThemeManager applyAppearanceToNavigationController:infoViewController traitCollection:self.traitCollection];

		infoViewController.modalPresentationStyle = UIModalPresentationPopover;
		infoViewController.preferredContentSize = CGSizeMake(420.0, 480.0);
		
		NSArray *passthoughViews = [self defaultPassthroughViews];
		
		UIPopoverPresentationController *ppc = infoViewController.popoverPresentationController;
		ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray: passthoughViews];
		ppc.backgroundColor = [UIColor clearColor];
		ppc.delegate = self;
		ppc.barButtonItem = sender;
		
		self.infoPopoverPresentationController = ppc;
		
		[self presentViewController:infoViewController animated:YES completion:nil];
	}
}

- (IBAction)actionAbout:(id)sender {
	
	if (_infoControllerOnScreen) {
		_infoControllerOnScreen = NO;
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	
	if (_aboutViewControllerOnScreen) {
		_aboutViewControllerOnScreen = NO;
		[self dismissViewControllerAnimated:YES completion:nil];
		
	} else {
		
		_aboutViewControllerOnScreen = YES;
		NSArray *passthoughViews = [self defaultPassthroughViews];
		UITableViewController *aboutViewController = [MADAboutTableViewController newAboutTableViewController];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
		navController.navigationBarHidden = YES;
		navController.modalPresentationStyle = UIModalPresentationPopover;
		
		UIPopoverPresentationController *ppc = navController.popoverPresentationController;
		ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray: passthoughViews];
		ppc.backgroundColor = [UIColor clearColor];
		ppc.delegate = self;
		ppc.barButtonItem = sender;
		
		self.aboutPopoverPresentationController = ppc;
		[self showViewController:navController animated: YES];
	}
}

- (IBAction)actionDocumentInformation:(id)sender {
	NSArray <NSIndexPath *> *selectedItems = [self.fileExplorerViewDelegate indexPathsForSelectedItems];
	NSMutableArray <MADMetaData *> *metadataItems = [[NSMutableArray alloc] initWithCapacity:selectedItems.count];
	
	for (NSIndexPath *indexPath in selectedItems) {
		MADMetaData *metadata = [self.fileExplorerDataSource metadataAtIndex: (NSUInteger)indexPath.item];
		[metadataItems addObject:metadata];
	}
	
	MADDocumentInformationTableViewController *documentInformation = [MADDocumentInformationTableViewController newDocumentInformationTableViewController];
	documentInformation.modalPresentationStyle = UIModalPresentationPopover;
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:documentInformation];
	navController.modalPresentationStyle = UIModalPresentationPopover;
	navController.presentationController.delegate = self;
	[MADThemeManager applyAppearanceToNavigationController:navController traitCollection:self.traitCollection];

	UIPopoverPresentationController *ppc = navController.popoverPresentationController;
	if (ppc) {
		ppc.barButtonItem = sender;
		ppc.delegate = self;
		NSArray *passthoughViews = [self defaultPassthroughViews];
		ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:passthoughViews];
		ppc.backgroundColor = [UIColor clearColor];
	}
	
	self.documentInformationPopoverPresentationController = ppc;
	
	documentInformation.metadataItems = metadataItems;
	
	[self presentViewController: navController animated: YES completion:^{
		[self actionEdit:self];
	}];
}

- (IBAction)actionStore:(id __unused)sender {
	
	UINavigationController *licensing = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeLicensing];
	[MADThemeManager applyAppearanceToNavigationController:licensing traitCollection:self.traitCollection];
	
	licensing.providesPresentationContextTransitionStyle = YES;
	licensing.definesPresentationContext = YES;
	licensing.modalPresentationStyle = UIModalPresentationFormSheet;
	licensing.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	licensing.presentationController.delegate = self;
	((MADStoreViewController *)licensing.viewControllers[0]).delegate = self;
	self.fileExplorerViewDelegate.showingPopover = YES;
	
	self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
	[self showViewController:licensing animated: YES];
}

- (IBAction)actionCancel:(id __unused)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
	[self.barButtonItemAddNewDocument setEnabled:YES];
}

- (IBAction)actionSearch:(id __unused)sender {
	
	if (self.searchBar.isHidden) {
		
		self.searchBar.hidden = NO;
		self.searchBar.showsCancelButton = NO;
		self.searchBar.alpha = 0.0;
		self.navigationItem.titleView.alpha = 1.0;
		self.navigationItem.leftBarButtonItem.enabled = NO;
		
		self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
		[self.searchBar sizeToFit];
		
		UIView *searchViewHolder = [[UIView alloc] initWithFrame:self.searchBar.bounds];
		self.searchBar.autoresizingMask = MADViewAutoresizingFlexable();
		searchViewHolder.autoresizingMask = MADViewAutoresizingFlexable();
		[searchViewHolder addSubview:self.searchBar];
		[searchViewHolder sizeToFit];
		self.searchBar.translucent = YES;
		self.searchBar.backgroundColor = [UIColor clearColor];
		self.searchBar.barTintColor = nil;
		self.searchBar.tintColor = [UIColor systemBlueColor];
		
		if (self.navigationItem.titleView != nil) {
		
			__weak MADExplorerController *weakSelf = self;
			UIView *titleView = (UIView * _Nonnull)self.navigationItem.titleView;
			[UIView transitionWithView: titleView
							  duration: 0.2
							   options: UIViewAnimationOptionCurveEaseOut
							animations: ^{
				__strong MADExplorerController *strongSelf = weakSelf;
				if (strongSelf) {
					strongSelf.searchBar.alpha = 1.0;
					strongSelf.navigationItem.titleView.alpha = 0.0;
					strongSelf.navigationItem.titleView = searchViewHolder;
				}
			} completion:^(BOOL __unused finished) {
				__strong MADExplorerController *strongSelf = weakSelf;
				if (strongSelf) {
					if (strongSelf.searchBar.isFirstResponder == NO) {
						[strongSelf.searchBar becomeFirstResponder];
						strongSelf.searchBar.hidden = NO;
					}
				}
			}];
		}
		
	} else {
		
		if (self.searchBar.text.length > 0) {
			self.searchBar.text = @"";
		}
		self.searchBar.hidden = YES;
		self.searchBar.alpha = 1.0;
		
		self.navigationItem.titleView.alpha = 0.0;
		self.navigationItem.leftBarButtonItem.enabled = YES;
		
		__weak MADExplorerController *weakSelf = self;
		UIView *titleView = self.navigationItem.titleView;
		
		[UIView transitionWithView: titleView duration: 0.2 options: UIViewAnimationOptionCurveEaseOut animations:^{
			__strong MADExplorerController *strongSelf = weakSelf;

			if (strongSelf) {
				strongSelf.searchBar.alpha = 0.0;
				strongSelf.navigationItem.titleView.alpha = 1.0;
				strongSelf.navigationItem.titleView = titleView;
			}
		} completion:^(BOOL finished) {
			if (finished) {
				__strong MADExplorerController *strongSelf = weakSelf;
				if (strongSelf) {
					strongSelf.searchBar.hidden = YES;
				}
			}
		}];
	}
}

- (IBAction)actionEdit:(id __unused)sender {
	BOOL startEdit = !self.isEditing;
	[self setEditing:startEdit animated:YES];
	if (startEdit) {
		self.barButtonItemAddNewDocument.enabled = NO;
		self.barButtonItemAbout.enabled = NO;
		self.barButtonItemInformation.enabled = NO;
		self.barButtonItemLicensing.enabled = NO;
		self.collectionView.allowsSelection = YES;
		self.collectionView.allowsMultipleSelection = YES;
		for (MADCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
			cell.wobbling = YES;
		}
		[self.navigationItem setRightBarButtonItem: self.barButtonItemEditDone animated: YES];
		
	} else {
		[self actionDone:nil];
	}
}

- (IBAction)actionDone:(id __unused)sender {

	self.editing = NO;
	self.barButtonItemAddNewDocument.enabled = YES;
	self.barButtonItemAbout.enabled = YES;
	self.barButtonItemLicensing.enabled = YES;
	self.barButtonItemInformation.enabled = YES;
	self.barButtonItemTrash.enabled = NO;
	self.barButtonItemInformationDocument.enabled = NO;
	self.barButtonItemDuplicate.enabled = NO;
	self.barButtonItemAction.enabled = NO;

	self.collectionView.allowsMultipleSelection = NO;
	
	[self.navigationItem setRightBarButtonItem:self.barButtonItemEdit animated:YES];
	for (NSIndexPath *path in self.collectionView.indexPathsForSelectedItems) {
		[self.collectionView deselectItemAtIndexPath:path animated:YES];
	}
	MADCollectionViewCellDocument *cell;
	for (cell in self.collectionView.visibleCells) {
		cell.wobbling = NO;
	}
}

- (IBAction)actionDownload:(id __unused)sender {
	UTType *madType = [UTType typeWithIdentifier:MADUtiType] ?: UTTypeData;
	UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[madType]
																										 asCopy:YES];
	picker.delegate = self;
	[self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)actionCut:(id)sender {
	[super cut:sender];
}

- (IBAction)actionCopy:(id)sender {
	[super copy:sender];
}

- (IBAction)actionPaste:(id __unused)sender {
	NSURL *url = [[UIPasteboard generalPasteboard].URL copy];
	NSData *data = [[NSData alloc] initWithContentsOfURL:url];
	NSURL *destinationUrl = [MADURLFactory newURLWithUniqueFilenameForURL: url];

	NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
	NSError *fileWrittingError = nil;
	[fileWrapper writeToURL: destinationUrl
					options: NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
		originalContentsURL: url
					  error: &fileWrittingError];
	if (fileWrittingError != nil) {
		os_log_error(GetDesignerLog(), "Error: %@", fileWrittingError);
		NSError *error = nil;
		[fileWrapper writeToURL: destinationUrl
						options: NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
			originalContentsURL: url
						  error: &error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "Error: %@", error);
		}
	}
	
	[self.collectionView reloadData];
}

- (IBAction)actionActivity:(id)sender {
	
	NSMutableArray *wrappedUrls = [[NSMutableArray alloc] initWithCapacity: self.fileExplorerDataSource.count];

	NSArray<NSIndexPath *> *indexPaths = self.collectionView.indexPathsForSelectedItems;
	MADMetaData *metadata;
	NSURL *fileURL;
	NSIndexPath *indexPath;
	for (indexPath in indexPaths) {
		metadata = [self.fileExplorerDataSource metadataAtIndex:(NSUInteger)indexPath.item];
		fileURL = [metadata.URL copy];
		[wrappedUrls addObject:fileURL];
	}
	
	NSArray *applicationActivities = [[NSArray alloc] init];
	NSArray *excludedActivityTypes = [[NSArray alloc] initWithObjects: UIActivityTypeAssignToContact,
									  UIActivityTypePostToFacebook,
									  UIActivityTypePostToFlickr,
									  UIActivityTypePostToTwitter,
									  UIActivityTypePostToVimeo,
									  UIActivityTypeAddToReadingList,
									  UIActivityTypePostToTencentWeibo,
									  UIActivityTypePostToWeibo,
									  UIActivityTypeSaveToCameraRoll, nil];
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems: wrappedUrls
																						 applicationActivities: applicationActivities];
	activityViewController.excludedActivityTypes = excludedActivityTypes;
	activityViewController.modalPresentationStyle = UIModalPresentationPopover;
	activityViewController.popoverPresentationController.barButtonItem = sender;
	activityViewController.popoverPresentationController.delegate = self;

	MADExplorerController * __weak weakself = self;
	activityViewController.completionWithItemsHandler = ^(NSString *__unused activityType, BOOL __unused completed,
														  NSArray *__unused returnedItems, NSError *__unused activityError) {
		for (UICollectionViewCell *cell in weakself.collectionView.visibleCells) {
			cell.selected = NO;
		}
	};
	
	[self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)actionDelete:(id)sender {

	NSArray *selectedItems = self.collectionView.indexPathsForSelectedItems;
	UIAlertController *alertController = [MADAlertController newAlertControllerDeleteItems:selectedItems.count
																				   confirm:^(UIAlertAction *__unused action) {
		
		for (NSIndexPath *selectedItem in selectedItems) {
			[self.fileExplorerDataSource removeItemAtIndex:(NSUInteger)selectedItem.item];
		}
		
	} cancel:^(UIAlertAction *__unused action) { }];
	
	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		alertController.popoverPresentationController.barButtonItem = sender;
	}
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)actionDuplicate:(id __unused)sender {
	for (NSIndexPath *selectedItem in self.collectionView.indexPathsForSelectedItems) {
		[self.fileExplorerDataSource duplicateItemAtIndex:(NSUInteger)selectedItem.item];
	}
}

- (IBAction)actionRename:(id)sender {
	
	if (self.isEditing)
		return;
		
	MADCollectionViewCellDocument *cellDocument;
	
	if ([sender isKindOfClass:[MADCollectionViewCellDocument class]]) {
		cellDocument = sender;
		
	} else if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
		UIView *contentView = ((UITapGestureRecognizer *)sender).view.superview;
		cellDocument = (MADCollectionViewCellDocument *)contentView.superview;
	}
	
	NSAssert(cellDocument != nil, @"Null cell at %s.", __PRETTY_FUNCTION__);
	
	NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
	MADMetaData *metaData = [self.fileExplorerDataSource metadataAtIndex: (NSUInteger)indexPath.item];
	
	NSString *textFieldText = [cellDocument.labelTitle.text copy];
	
	void (^handleRename)(UITextField *) = ^(UITextField *textField) {
		textField.text = [textFieldText copy];
		textField.clearButtonMode = UITextFieldViewModeAlways;
		textField.delegate = self;
	};
	
	void (^handleConfermation)(UIAlertAction *action, NSString *text) = ^(UIAlertAction *__unused action, NSString *text) {
		NSString *name = [self.class safeFilenameWithDesiredFilename:text];
		BOOL shortcircut = NO;
		
		if (name.length <= 0) {
			UIAlertController *alertError = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Validation Error", @"Validation Error")
																				message: NSLocalizedString(@"Filename not valid.", @"Filename not valid.")
																		 preferredStyle: UIAlertControllerStyleAlert];
			UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Dismiss", @"Dismiss")
														 style: UIAlertActionStyleDefault
													   handler: nil];
			[alertError addAction:ok];
			
			[self showViewController:alertError animated: YES];
			shortcircut = YES;
		}
		
		NSURL *url = [metaData.URL copy];
		if (!shortcircut && [self.class isUniqueFilename:name inDirectory:url]) {
			UIAlertController *alertError = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"File Exist", @"File Exist")
																		   message: NSLocalizedString(@"File already exist. Please choose a new name.", @"File already exist. Please choose a new name.")
																	preferredStyle: UIAlertControllerStyleAlert];
			UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Dismiss", @"Dismiss")
														 style: UIAlertActionStyleDefault
													   handler: nil];
			[alertError addAction:ok];
			[self showViewController:alertError animated: YES];
			shortcircut = YES;
		}
		
		if (!shortcircut && metaData.isUbiquitousItemDownloadingStatusNotDownloaded) {
			
			MADExplorerDataSource *fileExplorerDataSource = self.fileExplorerDataSource;
			
			void (^closeCompletion)(BOOL, NSURL *, NSURL *) = ^(BOOL successClose, NSURL *__unused fileURL, NSURL *__unused cleanupURL) {
				if (successClose)
					[fileExplorerDataSource rename:text
								itemAtIndex:(NSUInteger)indexPath.item];
			};
			
			MADocument *doc = [MADocument newManagedDocumentForURL:metaData.URL];
			
			void (^openCompletion)(BOOL) = ^(BOOL success) {
				if (success) [MADocument close: doc completion:closeCompletion];
			};
			
			[doc openWithCompletionHandler:openCompletion];
			
		} else {
			[self.fileExplorerDataSource rename:text itemAtIndex:(NSUInteger)indexPath.item];
		}
	};
	
	UIAlertController *alert = [MADExplorerController alertRenameDocument: handleRename
																  confirm: handleConfermation
																   cancel: nil];
	[self showViewController:alert animated: YES];
}

- (IBAction)actionEmail:(MADCollectionViewCellDocument *)cell {
	if ([MFMailComposeViewController canSendMail] == NO) {
		id alert = [MADExplorerController alertNotConfiguredForEmail];
		[self showViewController:alert animated: YES];
		return;
	}

	NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
	MADMetaData *metadata = [self.fileExplorerDataSource metadataAtIndex:(NSUInteger)indexPath.item];
	MADocument *documentReport = [MADocument newManagedDocumentForURL:metadata.URL];
	
	if (documentReport.documentState != UIDocumentStateClosed) {
		
		void (^handleCloseDocumentCompletion)(BOOL, NSURL *, NSURL *) = ^(BOOL success, NSURL *__unused fileURL, NSURL *__unused cleanupURL) {
			if (success) { [self actionEmail:cell]; }
		};
		[MADocument close: documentReport completion:handleCloseDocumentCompletion];
		
	} else {
		
		NSString *mimeType = [self mimeTypeForDocumentUTI:documentReport.fileType];
		NSMutableString *messageBody = [[NSMutableString alloc] initWithString:NSLocalizedString(@"The attached document can be opened with MAD Viewer.",
																								 @"The attached document can be opened with MAD Viewer.")];
		[messageBody appendString:@"\n\n"];
		
		MFMailComposeViewController *mailComposer = [MFMailComposeViewController ma_newMailComposeViewControllerWithBody: messageBody
																											  attachment: metadata.URL
																												mimeType: mimeType
																									  userInterfaceIdiom: self.traitCollection.userInterfaceIdiom];
		mailComposer.mailComposeDelegate = self;
		[self showViewController:mailComposer animated: YES];
	}
}

- (void)actionActivateEditMode:(UICollectionViewCell *)sender {
	[self actionEdit:nil];
	[self selectCell:sender];
}

+ (UIAlertController *)alertRenameDocument:(void (^)(UITextField *textField))textFieldConfig
								   confirm:(void (^)(UIAlertAction *action, NSString *text))handlerConfirm
									cancel:(void (^)(UIAlertAction *action))handlerCancel {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Rename Document", @"Rename Document")
																   message: NSLocalizedString(@"Please enter a new name for the document.", @"Please enter a new name for the document.")
															preferredStyle: UIAlertControllerStyleAlert];
	[alert addTextFieldWithConfigurationHandler:textFieldConfig];

	UIAlertAction *actionDefault = [UIAlertAction actionWithTitle: NSLocalizedString(@"Rename", @"Rename")
															style: UIAlertActionStyleDefault
														  handler: ^(UIAlertAction *action) {
		UITextField *textField = alert.textFields.firstObject;
		NSString *newText = [textField.text copy];
		handlerConfirm(action, newText);
	}];
	[alert addAction:actionDefault];

	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
											style: UIAlertActionStyleCancel
										  handler: handlerCancel];
	[alert addAction:actionCancel];
	return alert;
}

+ (UIAlertController *)alertNotConfiguredForEmail {
	id alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Alert", @"Alert")
												   message: NSLocalizedString(@"Device is not configured for email.", @"Device is not configured for email.")
											preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
												 style: UIAlertActionStyleDefault
											   handler: nil];
	[alert addAction:ok];
	return alert;
}

+ (UIAlertController *)alertNotifyCloudSignOut:(void (^)(UIAlertAction *action))handler {
	NSString *MADMessageCloudSignout = @"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.";
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"iCloud Sign Out", @"iCloud Sign Out")
																			 message: NSLocalizedString(MADMessageCloudSignout, MADMessageCloudSignout)
																	  preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle: NSLocalizedString(@"Dismiss", @"Dismiss")
															style: UIAlertActionStyleDefault
														  handler: handler];
	[alertController addAction:actionConfirm];
	return alertController;
}

@end
#pragma clang diagnostic pop
