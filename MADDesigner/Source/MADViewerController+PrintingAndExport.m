//
//  MADViewerController+PrintingAndExport.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADViewerController+PrintingAndExport.h"

@implementation MADViewerController (PrintingAndExport)

#pragma mark -
#pragma mark MADPrintingProtocol

- (MADPrintPageRenderer *)printPageRenderer {
	return self.printPageRendererReport;
}

#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController * __unused)controller {
	return self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? self.navigationController : self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController * __unused)controller {
	NSURL *temporaryFile = [[NSURL fileURLWithPath: NSTemporaryDirectory()] URLByAppendingPathComponent:@"preview.pdf"];
	NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager] removeItemAtURL:temporaryFile
															 error:&error];
	if (!success && error != nil) {
		os_log_error(GetDesignerLog(), "Error: %@", error);
	}
	NSAssert(success, @"Failed to delete file.");
}

- (UIViewController *)previewViewControllerForInteractionController:(UIDocumentInteractionController * __unused)controller {
	return self;
}

- (void)prepareForInteractionController:(UIDocumentInteractionController * __unused)controller
							 completion:(void (^)(BOOL))completion {
	completion(YES);
}

#pragma mark -
#pragma mark Actions & Activities

- (IBAction)activity:(id)sender {
	_activityExporting = YES;
	self.pageSlider.enabled = NO;
	
	MADActivityItemProviderPdf *activityItemProviderPdf = self.activityItemProviderPdf;
	activityItemProviderPdf.delegate = self;
	NSArray *activityItems = [[NSArray alloc] initWithObjects: activityItemProviderPdf, nil];
	self.activityItemProviderPdf = activityItemProviderPdf;
	
	MADActivityReportPrintPreview *printPreview = [[MADActivityReportPrintPreview alloc] init];
	printPreview.delegate = self;
	
	NSArray *applicationActivities = [[NSArray alloc] initWithObjects: printPreview, nil];
	
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
																						 applicationActivities:applicationActivities];

	MADViewerController * __weak weakself = self;

	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed,
														  NSArray *__unused returnedItems, NSError *__unused activityError) {
		MADViewerController *sself = weakself;
		sself.pageSlider.enabled = YES;
		sself->_activityExporting = NO;
		if (completed || (!completed && activityType == nil)) {
			[(MADTabBarController *)sself.tabBarController enableTabBarItems];
		} else {
			if (activityType.length > 0) {
				if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {
					id document = sself.document;
					[document updatePrintingReportFormatter];
					MADPrintPageRenderer *printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource: document];
					
					[UIPrintInteractionController sharedPrintController].delegate = document;
					[UIPrintInteractionController sharedPrintController].printPageRenderer = printPageRenderer;
					if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
						
						[MADViewerController setNavigationBarAppearanceHighlighted];
						MADViewerController * __weak weakself2 = sself;
						[[UIPrintInteractionController sharedPrintController] presentAnimated:YES completionHandler:^(UIPrintInteractionController *__unused printInteractionController, BOOL animatinCompleted, NSError *__unused error) {
							if (animatinCompleted) {
								MADViewerController *sself2 = weakself2;
								[MADViewerController setNavigationBarAppearanceTinted];
								
								sself2.pageSlider.enabled = YES;
								sself2->_activityExporting = NO;
								[(MADTabBarController *)sself2.tabBarController enableTabBarItems];
							}
						}];
					}
				}
			} else {
				[(MADTabBarController *)sself.tabBarController enableTabBarItems];
			}
		}
	};
	activityViewController.modalPresentationStyle = UIModalPresentationPopover;
	
	UIPopoverPresentationController *ppc = activityViewController.popoverPresentationController;
	ppc.barButtonItem = sender;
	
	[self presentViewController:activityViewController animated:YES completion:nil];
	[self.tabBarController disableTabBarItems];
}

- (MADActivityItemProviderPdf *)activityItemProviderPdf {
	NSString *temporaryDirectoryPath = NSTemporaryDirectory();
	NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
	NSURL *urlEmpty = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
	MADActivityItemProviderPdf *activityItemProviderPdf = [[MADActivityItemProviderPdf alloc] initWithPlaceholderItem:urlEmpty];
	activityItemProviderPdf.document = self.document;
	return activityItemProviderPdf;
}

#pragma mark -
#pragma mark MTActivityItemProviderDelegate

- (void)showPrintDialog {
	MADViewerController * __weak weakself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
		if (sharedController) {
			MADViewerController *sself = weakself;
			if (!sself) return;
			
			MADocument *document = sself.document;
			document.activityDelegate = sself;
			[document updatePrintingReportFormatter];
			UIPrintPageRenderer *printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource: document];
			sharedController.printPageRenderer = printPageRenderer;
			sharedController.delegate = document;
			
			MADViewerController * __weak weakself2 = sself;
			[sharedController presentFromBarButtonItem: sself.barButtonItemActivity
											  animated: YES
									 completionHandler: ^(UIPrintInteractionController *__unused pic, BOOL __unused completed, NSError *__unused error) {
				MADViewerController *sself2 = weakself2;
				sself2.pageSlider.enabled = YES;
				[sself2.tabBarController enableTabBarItems];
			}];
		}
	});
}

#pragma mark -
#pragma mark MADActivityProtocol

- (UIViewController *)activeViewController { return self; }

@end

#pragma mark -
#pragma mark MADOperationLoadPrintPageRender

@interface MADOperationLoadPrintPageRender ()
@property (readwrite, nonatomic, weak) MADocument *document;
@property (readwrite, nonatomic, weak) MADPrintPageRenderer *printPageRenderer;
@end

@implementation MADOperationLoadPrintPageRender

- (instancetype)initWithDocument:(MADocument *)document {
	if (self = [super init]) {
		[self setDocument: document];
	}
	return self;
}

- (void)main {
	MADPrintPageRenderer *printPageRenderer = nil;
	MADocument *document = self.document;

	if (!self.isCancelled) {
		printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource:document];
		self.printPageRenderer = printPageRenderer;
	}
	
	if (!self.isCancelled && printPageRenderer == nil) {
		[document activeDocumentModel];
		printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource:document];
		self.printPageRenderer = printPageRenderer;
	}
	
	if (!self.isCancelled) {
		document.reportFormatter.didRefresh = NO;
	}
}

@end

#pragma mark -
#pragma mark MADOperationLoadDocument

@interface MADOperationLoadDocument ()
@property (readwrite, nonatomic, weak) MADocument *document;
@end

@implementation MADOperationLoadDocument {
	BOOL _executing;
	BOOL _finished;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary <NSKeyValueChangeKey, id> *)change
					   context:(void *)context {
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (instancetype)initWithDocument:(MADocument *)document {
	if (self = [super init]) {
		[self setDocument: document];
		_executing = NO;
		_finished = NO;
	}
	return self;
}

- (BOOL)isAsynchronous {
	return YES;
}

- (BOOL)isFinished { return _finished; }

- (BOOL)isExecuting { return _executing; }

- (void)main {
	MADocument *document = self.document;
	
	if (![self isCancelled]) {
		document.limitResultsDesignMode = [MADStoreKitController sharedObject].isReportingLimited;
	}
	
	if (![self isCancelled]) {
		[document activeDocumentModel];
		[document resetMainQuery];
	}
	
	if (![self isCancelled]) {
		[document prepareForQuery];
	}
	
	if (![self isCancelled]) {
		[document.reportFormatter loadFromCache: document.paper.paperSize];
		
		[self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
		_finished = YES;
		[self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
		
		[self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
		_executing = NO;
		[self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
	} else {
		[self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
		_finished = YES;
		[self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
		
		[self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
		_executing = NO;
		[self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
	}
}

@end
