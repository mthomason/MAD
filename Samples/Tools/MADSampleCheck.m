//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADSampleCheck.m
//  Samples/Tools
//
//  The recipient check for the curated samples.  It drives the same macOS app
//  objects the window uses -- MADMacDocument, MADMacWindowController, the three
//  workspaces, and MADMacConnectionWindowController -- and writes PNG/PDF
//  snapshots of every state, so it runs where screen capture is unavailable.
//
//  Usage:
//    MADSampleCheck <samples-directory> <screenshots-directory>
//
//  The PostgreSQL sample is checked when it exists and MAD_PG_SAMPLE_PASSWORD is
//  set.  The checker deletes the connection's Keychain entries first, so the
//  first refresh has no remembered password.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <Security/Security.h>

#import "MADMacConnectionWindowController.h"
#import "MADMacDesignerViewController.h"
#import "MADMacDocument.h"
#import "MADMacViewerViewController.h"
#import "MADMacWindowController.h"

#import <MAD/MAD.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADKeyChain.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <MADSqlite3/MADDataTableFast.h>

/// The viewer's row-grid decision and controls are implementation details; the
/// checker reads them just as the app's own smoke test does.
@interface MADMacViewerViewController (MADSampleCheck)
@property (nonatomic, readonly) PDFView *pdfView;
@property (nonatomic, readonly) NSTextField *statusLabel;
@property (nonatomic, readonly, nullable) NSError *lastRefreshError;
@property (nonatomic, readonly) NSTableView *rowGridView;
- (BOOL)isShowingRowGrid;
- (void)refreshReportAction:(nullable id)sender;
@end

@interface MADMacConnectionWindowController (MADSampleCheck)
@property (nonatomic, readonly) NSTextField *hostField;
@property (nonatomic, readonly) NSTextField *databaseField;
@property (nonatomic, readonly) NSTextField *usernameField;
@property (nonatomic, readonly) NSSecureTextField *passwordField;
@property (nonatomic, readonly) NSButton *saveKeychainCheckbox;
- (void)createDocumentAction:(nullable id)sender;
@end

static int sFailures = 0;

static void SamplePass(NSString *format, ...) {
	va_list args;
	va_start(args, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	printf("PASS  %s\n", message.UTF8String);
}

static void SampleFail(NSString *format, ...) {
	va_list args;
	va_start(args, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	fprintf(stderr, "FAIL  %s\n", message.UTF8String);
	sFailures++;
}

static BOOL SampleWait(BOOL (^condition)(void), NSTimeInterval timeout) {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
	while (!condition() && deadline.timeIntervalSinceNow > 0) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
	}
	return condition();
}

static BOOL SampleWriteSnapshots(NSWindow *window, NSString *directory, NSString *name) {
	if (window == nil) return NO;
	[window layoutIfNeeded];
	NSView *target = window.contentView.superview ?: window.contentView;
	[target layoutSubtreeIfNeeded];
	[target displayIfNeeded];
	NSRect bounds = target.bounds;

	NSData *pdf = [target dataWithPDFInsideRect:bounds];
	if (pdf.length > 0) {
		NSString *pdfPath = [directory stringByAppendingPathComponent:
							 [name stringByAppendingPathExtension:@"pdf"]];
		[pdf writeToFile:pdfPath atomically:YES];

		// A PDFView's page is vector content that cacheDisplayInRect can miss, so
		// the viewer screenshots come from the window's PDF, rendered by PDFKit.
		PDFDocument *pdfDocument = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfPath]];
		PDFPage *page = [pdfDocument pageAtIndex:0];
		if (page != nil) {
			NSRect pageBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
			NSImage *image = [page thumbnailOfSize:NSMakeSize(pageBounds.size.width * 2.0,
															  pageBounds.size.height * 2.0)
											forBox:kPDFDisplayBoxMediaBox];
			NSData *imageData = [image TIFFRepresentation];
			NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
			NSData *viewPNG = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
			[viewPNG writeToFile:[directory stringByAppendingPathComponent:
								 [name stringByAppendingString:@"-view.png"]] atomically:YES];
		}
	}

	NSBitmapImageRep *rep = [target bitmapImageRepForCachingDisplayInRect:bounds];
	if (rep == nil) return NO;
	[target cacheDisplayInRect:bounds toBitmapImageRep:rep];
	NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
	return [png writeToFile:[directory stringByAppendingPathComponent:
							[name stringByAppendingPathExtension:@"png"]] atomically:YES];
}

static BOOL SampleWritePDFFirstPagePNG(NSURL *pdfURL, NSString *pngPath) {
	PDFDocument *pdfDocument = [[PDFDocument alloc] initWithURL:pdfURL];
	PDFPage *page = [pdfDocument pageAtIndex:0];
	if (page == nil) return NO;
	NSRect pageBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
	NSImage *image = [page thumbnailOfSize:NSMakeSize(pageBounds.size.width * 2.0,
													  pageBounds.size.height * 2.0)
									forBox:kPDFDisplayBoxMediaBox];
	NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
	NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
	return [png writeToFile:pngPath atomically:YES];
}

/// Exports the actual report (not the window) so a screenshot shows what the user
/// prints, independent of how a PDFView snapshot is cached.
static BOOL SampleExportReportPDF(MADHeadlessDocument *document,
								  RptqQuery *query,
								  NSString *directory,
								  NSString *name) {
	id<MADReportExporting> exporter = [[MADReportExporterPDF alloc] init];
	NSString *pdfPath = [directory stringByAppendingPathComponent:
						 [name stringByAppendingString:@"-report.pdf"]];
	NSURL *pdfURL = [NSURL fileURLWithPath:pdfPath];
	NSError *error = nil;
	BOOL ok = NO;
	if ([exporter respondsToSelector:@selector(exportDocument:query:toURL:options:error:)]) {
		ok = [exporter exportDocument:document
								query:query
								toURL:pdfURL
							  options:MADReportExportOptionsNone
								error:&error];
	} else {
		ok = [exporter exportDocument:document
								toURL:pdfURL
							  options:MADReportExportOptionsNone
								error:&error];
	}
	if (!ok) {
		SampleFail(@"%@: report PDF export: %@", name, error.localizedDescription ?: @"(no message)");
		return NO;
	}
	SampleWritePDFFirstPagePNG(pdfURL, [directory stringByAppendingPathComponent:
									   [name stringByAppendingString:@"-report.png"]]);
	return YES;
}

static MADMacDocument *SampleOpenDocument(NSURL *url, NSString *label) {
	NSError *error = nil;
	MADMacDocument *document = [[MADMacDocument alloc] initWithContentsOfURL:url
																	 ofType:@"com.thomason.mad"
																	  error:&error];
	if (document == nil) {
		SampleFail(@"%@: open: %@", label, error.localizedDescription ?: @"(no message)");
		return nil;
	}
	[document makeWindowControllers];
	MADMacWindowController *windowController = document.windowControllers.firstObject;
	NSWindow *window = windowController.window;
	[window makeKeyAndOrderFront:nil];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	return document;
}

static BOOL SampleRefresh(MADMacDocument *document,
						  MADMacViewerViewController *viewer,
						  NSUInteger expectedRows,
						  NSString *label) {
	[viewer refreshReportAction:nil];
	BOOL settled = SampleWait(^BOOL{
		MADDataResult *result = [document resultForQuery:document.selectedQuery];
		return (document.headlessDocument.refreshed && result != nil) ||
			   viewer.lastRefreshError != nil;
	}, 60.0);
	if (!settled) {
		SampleFail(@"%@: refresh did not settle", label);
		return NO;
	}
	if (viewer.lastRefreshError != nil) {
		SampleFail(@"%@: refresh: %@", label, viewer.lastRefreshError.description);
		return NO;
	}
	MADDataResult *result = [document resultForQuery:document.selectedQuery];
	NSUInteger rows = result.numberOfRows;
	if (rows != expectedRows) {
		SampleFail(@"%@: %lu rows, expected %lu", label, (unsigned long)rows, (unsigned long)expectedRows);
		return NO;
	}
	SamplePass(@"%@ refreshed: %lu rows", label, (unsigned long)rows);
	return YES;
}

static void SampleClearKeychainForConnection(NSString *connectionString) {
	if (connectionString.length == 0) return;
	// The app writes each half under MADKeyChain's account descriptions, so a delete
	// that names only the service leaves the item behind.  Delete the exact
	// class+service+account triple without reading the secret (a data read can prompt
	// for authorization in a test process).  Only this connection's key is cleared, not
	// the driver-identifier fallback the app also probes; deleting that would remove
	// credentials the user saved for other servers.
	for (NSString *prefix in @[@"u:", @"p:"]) {
		NSString *service = [prefix stringByAppendingString:connectionString];
		NSString *account = [prefix isEqualToString:@"u:"]
			? MADKeyChainUsernameAccountDesc
			: MADKeyChainPasswordAccountDesc;
		NSDictionary *query = @{
			(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
			(__bridge id)kSecAttrService : service,
			(__bridge id)kSecAttrAccount : account
		};
		SecItemDelete((__bridge CFDictionaryRef)query);
	}
}

static BOOL SampleDocumentStoresPassword(MADHeadlessDocument *document, NSString *password);

static NSUInteger SampleElementCount(MADMacDocument *document) {
	NSUInteger count = 0;
	for (RptqDocumentSection *section in [document orderedSections]) {
		for (RptqDocumentSectionRows *row in section.hasRows) {
			count += row.hasObjects.count;
		}
	}
	return count;
}

#pragma mark - One sample at a time

static BOOL CheckStandard(NSURL *url, NSString *screenshots) {
	MADMacDocument *document = SampleOpenDocument(url, @"Chinook-Standard.mad");
	if (document == nil) return NO;
	MADMacWindowController *wc = document.windowControllers.firstObject;
	MADMacViewerViewController *viewer = wc.viewerViewController;

	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	NSUInteger sections = [document orderedSections].count;
	if (sections < 5) {
		SampleFail(@"Chinook-Standard.mad: Designer has only %lu bands", (unsigned long)sections);
		return NO;
	}
	SampleWriteSnapshots(wc.window, screenshots, @"standard-designer");

	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	BOOL refreshed = SampleRefresh(document, viewer, 275, @"Chinook-Standard.mad");
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	NSUInteger pages = viewer.pdfView.document.pageCount;
	if (refreshed && pages < 2) {
		SampleFail(@"Chinook-Standard.mad: rendered %lu pages", (unsigned long)pages);
		refreshed = NO;
	}
	if (refreshed) SamplePass(@"Chinook-Standard.mad rendered %lu pages", (unsigned long)pages);
	SampleWriteSnapshots(wc.window, screenshots, @"standard-viewer");
	SampleExportReportPDF(document.headlessDocument, document.selectedQuery, screenshots, @"standard");
	return refreshed;
}

static BOOL CheckGrouped(NSURL *url, NSString *screenshots) {
	MADMacDocument *document = SampleOpenDocument(url, @"Chinook-Grouped.mad");
	if (document == nil) return NO;
	MADMacWindowController *wc = document.windowControllers.firstObject;
	MADMacViewerViewController *viewer = wc.viewerViewController;

	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	NSUInteger sections = [document orderedSections].count;
	if (sections < 7) {
		SampleFail(@"Chinook-Grouped.mad: Designer has only %lu bands", (unsigned long)sections);
		return NO;
	}
	SampleWriteSnapshots(wc.window, screenshots, @"grouped-designer");

	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	BOOL refreshed = SampleRefresh(document, viewer, 412, @"Chinook-Grouped.mad");
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	SampleExportReportPDF(document.headlessDocument, document.selectedQuery, screenshots, @"grouped");
	NSUInteger pages = viewer.pdfView.document.pageCount;
	if (refreshed && pages < 2) {
		SampleFail(@"Chinook-Grouped.mad: rendered %lu pages; expected a multi-page grouped report",
				   (unsigned long)pages);
		refreshed = NO;
	}
	if (refreshed) SamplePass(@"Chinook-Grouped.mad rendered %lu pages", (unsigned long)pages);
	SampleWriteSnapshots(wc.window, screenshots, @"grouped-viewer");
	return refreshed;
}

static BOOL CheckComposition(NSURL *url, NSString *screenshots) {
	MADMacDocument *document = SampleOpenDocument(url, @"Chinook-Composition.mad");
	if (document == nil) return NO;
	MADMacWindowController *wc = document.windowControllers.firstObject;
	MADMacViewerViewController *viewer = wc.viewerViewController;

	if (!document.isComposed || [document allQueries].count != 3) {
		SampleFail(@"Chinook-Composition.mad: composed=%d queries=%lu",
				   document.isComposed, (unsigned long)[document allQueries].count);
		return NO;
	}
	if (wc.nodePickerPopup == nil || wc.nodePickerPopup.numberOfItems != 3) {
		SampleFail(@"Chinook-Composition.mad: node picker has %ld items",
				   (long)wc.nodePickerPopup.numberOfItems);
		return NO;
	}

	RptqQuery *root = document.rootQuery;
	RptqQuery *albums = nil, *artists = nil;
	for (RptqQuery *query in [document allQueries]) {
		if ([query.name isEqualToString:@"Albums"]) albums = query;
		if ([query.name isEqualToString:@"Artists"]) artists = query;
	}
	if (root == nil || albums == nil || artists == nil) {
		SampleFail(@"Chinook-Composition.mad: missing Result/Albums/Artists node");
		return NO;
	}

	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	SampleWriteSnapshots(wc.window, screenshots, @"composition-result-designer");

	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	BOOL refreshed = SampleRefresh(document, viewer, 347, @"Chinook-Composition.mad Result");
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	NSUInteger resultPages = viewer.pdfView.document.pageCount;
	if (refreshed && resultPages < 1) {
		SampleFail(@"Chinook-Composition.mad: Result rendered no pages");
		refreshed = NO;
	}
	SampleWriteSnapshots(wc.window, screenshots, @"composition-result-viewer");
	SampleExportReportPDF(document.headlessDocument, root, screenshots, @"composition-result");

	MADHeadlessDocument *headless = document.headlessDocument;
	MADDataResult *albumResult = headless.nodeResults[@(albums.identifier)];
	MADDataResult *artistResult = headless.nodeResults[@(artists.identifier)];
	if (albumResult == nil || albumResult.numberOfRows != 347) {
		SampleFail(@"Chinook-Composition.mad: Albums source has %lu rows",
				   (unsigned long)albumResult.numberOfRows);
		refreshed = NO;
	} else {
		SamplePass(@"Chinook-Composition.mad Albums source refreshed: %lu rows",
				   (unsigned long)albumResult.numberOfRows);
	}
	if (artistResult == nil || artistResult.numberOfRows != 275) {
		SampleFail(@"Chinook-Composition.mad: Artists source has %lu rows",
				   (unsigned long)artistResult.numberOfRows);
		refreshed = NO;
	} else {
		SamplePass(@"Chinook-Composition.mad Artists source refreshed: %lu rows",
				   (unsigned long)artistResult.numberOfRows);
	}

	// The Albums source has its own layout: its Designer bands and field list,
	// then a paged Viewer report.
	document.selectedQuery = albums;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MADMacDesignerViewController *designer = wc.designerViewController;
	NSUInteger albumElements = SampleElementCount(document);
	if (designer.displayedQueryFields.count != 3 || albumElements == 0) {
		SampleFail(@"Chinook-Composition.mad: Albums Designer fields=%lu elements=%lu",
				   (unsigned long)designer.displayedQueryFields.count,
				   (unsigned long)albumElements);
		refreshed = NO;
	} else {
		SamplePass(@"Chinook-Composition.mad Albums Designer: 3 fields, %lu layout elements",
				   (unsigned long)albumElements);
	}
	SampleWriteSnapshots(wc.window, screenshots, @"composition-albums-designer");

	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	NSUInteger albumPages = viewer.pdfView.document.pageCount;
	BOOL albumGrid = [viewer isShowingRowGrid];
	if (albumGrid || albumPages < 1) {
		SampleFail(@"Chinook-Composition.mad: Albums source showed %@%lu pages",
				   albumGrid ? @"a row grid, not " : @"",
				   (unsigned long)albumPages);
		refreshed = NO;
	} else {
		SamplePass(@"Chinook-Composition.mad Albums source rendered %lu pages", (unsigned long)albumPages);
	}
	SampleWriteSnapshots(wc.window, screenshots, @"composition-albums-viewer");
	SampleExportReportPDF(document.headlessDocument, albums, screenshots, @"composition-albums");

	// The Artists source has no layout elements: its Designer shows the empty bands,
	// and the Viewer must show the row grid.
	document.selectedQuery = artists;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	if (designer.displayedQueryFields.count != 2 || SampleElementCount(document) != 0) {
		SampleFail(@"Chinook-Composition.mad: Artists Designer fields=%lu elements=%lu",
				   (unsigned long)designer.displayedQueryFields.count,
				   (unsigned long)SampleElementCount(document));
		refreshed = NO;
	} else {
		SamplePass(@"Chinook-Composition.mad Artists Designer: 2 fields, no layout elements");
	}
	SampleWriteSnapshots(wc.window, screenshots, @"composition-artists-designer");

	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	BOOL artistGrid = [viewer isShowingRowGrid];
	NSUInteger artistColumns = viewer.rowGridView.numberOfColumns;
	NSUInteger artistRows = artistResult.numberOfRows;
	if (!artistGrid || artistColumns < 2 || artistRows != 275) {
		SampleFail(@"Chinook-Composition.mad: Artists source grid=%d columns=%lu rows=%lu",
				   artistGrid, (unsigned long)artistColumns, (unsigned long)artistRows);
		refreshed = NO;
	} else {
		SamplePass(@"Chinook-Composition.mad Artists source showed a %lu-column, %lu-row grid",
				   (unsigned long)artistColumns, (unsigned long)artistRows);
	}
	SampleWriteSnapshots(wc.window, screenshots, @"composition-artists-grid");

	document.selectedQuery = root;
	return refreshed;
}

static BOOL CheckCopiedAndReopened(NSURL *samplesDirectory, NSString *screenshots) {
	NSString *tempRoot = [NSTemporaryDirectory() stringByAppendingPathComponent:
						  [NSString stringWithFormat:@"mad-samples-copy-%@", NSUUID.UUID.UUIDString]];
	NSURL *tempRootURL = [NSURL fileURLWithPath:tempRoot isDirectory:YES];
	NSURL *copyDirectory = [tempRootURL URLByAppendingPathComponent:@"Reports" isDirectory:YES];
	NSError *error = nil;
	[[NSFileManager defaultManager] createDirectoryAtURL:tempRootURL
							withIntermediateDirectories:YES
											 attributes:nil
												  error:&error];
	if (![[NSFileManager defaultManager] copyItemAtURL:samplesDirectory toURL:copyDirectory error:&error]) {
		SampleFail(@"could not copy samples outside the repo: %@", error.localizedDescription);
		return NO;
	}

	NSURL *standard = [copyDirectory URLByAppendingPathComponent:@"Chinook-Standard.mad" isDirectory:NO];
	MADMacDocument *document = SampleOpenDocument(standard, @"copied Chinook-Standard.mad");
	if (document == nil) return NO;
	MADMacWindowController *wc = document.windowControllers.firstObject;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	BOOL refreshed = SampleRefresh(document, wc.viewerViewController, 275, @"copied Chinook-Standard.mad");

	NSURL *saved = [copyDirectory URLByAppendingPathComponent:@"Saved-Chinook-Standard.mad" isDirectory:NO];
	NSError *saveError = nil;
	BOOL savedOK = [document writeToURL:saved
								 ofType:@"com.thomason.mad"
					   forSaveOperation:NSSaveOperation
					originalContentsURL:standard
								  error:&saveError];
	if (!savedOK) {
		SampleFail(@"save a copied standard sample: %@", saveError.localizedDescription);
		refreshed = NO;
	} else {
		SamplePass(@"saved a copied standard sample");
	}

	MADMacDocument *reopened = SampleOpenDocument(saved, @"reopened saved sample");
	if (reopened == nil) {
		SampleFail(@"reopen the saved sample");
		return NO;
	}
	MADMacWindowController *reopenedWC = reopened.windowControllers.firstObject;
	[reopenedWC switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	BOOL reopenedOK = SampleRefresh(reopened, reopenedWC.viewerViewController, 275, @"reopened saved sample");
	SampleWriteSnapshots(reopenedWC.window, screenshots, @"copied-reopened-standard-viewer");

	NSURL *composition = [copyDirectory URLByAppendingPathComponent:@"Chinook-Composition.mad" isDirectory:NO];
	MADMacDocument *compositionDoc = SampleOpenDocument(composition, @"copied Chinook-Composition.mad");
	if (compositionDoc == nil) return NO;
	MADMacWindowController *compositionWC = compositionDoc.windowControllers.firstObject;
	[compositionWC switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	BOOL compositionOK = SampleRefresh(compositionDoc, compositionWC.viewerViewController, 347,
									   @"copied Chinook-Composition.mad");

	NSURL *savedCompositionURL = [copyDirectory URLByAppendingPathComponent:@"Saved-Chinook-Composition.mad" isDirectory:NO];
	NSError *compositionSaveError = nil;
	BOOL savedComposition = [compositionDoc writeToURL:savedCompositionURL
											   ofType:@"com.thomason.mad"
									 forSaveOperation:NSSaveOperation
								  originalContentsURL:composition
												error:&compositionSaveError];
	if (!savedComposition) {
		SampleFail(@"save a copied composition: %@", compositionSaveError.localizedDescription);
		compositionOK = NO;
	}
	MADMacDocument *reopenedComposition = savedComposition
		? SampleOpenDocument(savedCompositionURL, @"reopened composition")
		: nil;
	BOOL reopenedCompositionOK = NO;
	if (reopenedComposition != nil) {
		MADMacWindowController *reopenedCompositionWC = reopenedComposition.windowControllers.firstObject;
		[reopenedCompositionWC switchToWorkspaceTab:MADMacWorkspaceTabViewer];
		reopenedCompositionOK = SampleRefresh(reopenedComposition,
											  reopenedCompositionWC.viewerViewController,
											  347,
											  @"reopened composition") &&
			reopenedComposition.isComposed &&
			[reopenedComposition allQueries].count == 3;
		RptqQuery *reopenedAlbums = nil, *reopenedArtists = nil;
		for (RptqQuery *query in [reopenedComposition allQueries]) {
			if ([query.name isEqualToString:@"Albums"]) reopenedAlbums = query;
			if ([query.name isEqualToString:@"Artists"]) reopenedArtists = query;
		}
		reopenedComposition.selectedQuery = reopenedAlbums;
		[reopenedCompositionWC switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
		BOOL albumsLayoutSurvived = reopenedAlbums != nil && SampleElementCount(reopenedComposition) > 0;
		reopenedComposition.selectedQuery = reopenedArtists;
		[reopenedCompositionWC switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
		BOOL artistsLayoutlessSurvived = reopenedArtists != nil && SampleElementCount(reopenedComposition) == 0;
		reopenedCompositionOK = reopenedCompositionOK && albumsLayoutSurvived && artistsLayoutlessSurvived;
		if (reopenedCompositionOK) {
			SamplePass(@"reopened composition kept the Result, the Albums layout and the layout-less Artists source");
		} else {
			SampleFail(@"reopened composition lost a node or a source layout");
		}
	}

	[[NSFileManager defaultManager] removeItemAtURL:tempRootURL error:NULL];
	return refreshed && reopenedOK && compositionOK && reopenedCompositionOK;
}

static BOOL CheckPostgres(NSURL *url, NSString *screenshots) {
	NSString *password = NSProcessInfo.processInfo.environment[@"MAD_PG_SAMPLE_PASSWORD"];
	if (password.length == 0) {
		printf("SKIP  PostgreSQL sample: MAD_PG_SAMPLE_PASSWORD is not set\n");
		return YES;
	}

	// A first run must not find a remembered credential.
	NSString *connectionString = @"(PostgreSQL)[127.0.0.1:5432]chinook";
	SampleClearKeychainForConnection(connectionString);

	MADMacDocument *document = SampleOpenDocument(url, @"PostgreSQL-Chinook.mad");
	if (document == nil) return NO;
	if (SampleDocumentStoresPassword(document.headlessDocument, password)) {
		SampleFail(@"PostgreSQL-Chinook.mad stores the test password");
		return NO;
	}
	MADMacWindowController *wc = document.windowControllers.firstObject;
	MADMacViewerViewController *viewer = wc.viewerViewController;

	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[viewer refreshReportAction:nil];

	// With no stored password the refresh must ask for one rather than fail silently.
	BOOL sheetShown = SampleWait(^BOOL{
		return wc.activeConnectionSheetController != nil;
	}, 30.0);
	if (!sheetShown) {
		SampleFail(@"PostgreSQL-Chinook.mad: refresh did not present the connection sheet (error: %@)",
				   viewer.lastRefreshError.description ?: @"none");
		return NO;
	}
	MADMacConnectionWindowController *sheet = wc.activeConnectionSheetController;
	// A sheet attached in an offscreen run has populated controls but no drawn
	// field editor until its window is ordered front and laid out.
	[sheet.window makeKeyAndOrderFront:nil];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
	NSString *host = sheet.hostField.stringValue;
	NSString *database = sheet.databaseField.stringValue;
	NSString *user = sheet.usernameField.stringValue;
	NSString *shownPassword = sheet.passwordField.stringValue;
	if (![host isEqualToString:@"127.0.0.1"] ||
		![database isEqualToString:@"chinook"] ||
		![user isEqualToString:@"mad"] ||
		shownPassword.length != 0) {
		SampleFail(@"PostgreSQL-Chinook.mad: sheet host='%@' database='%@' user='%@' password='%ld chars'",
				   host, database, user, (long)shownPassword.length);
		return NO;
	}
	SamplePass(@"PostgreSQL-Chinook.mad asked for the password with host=%@ database=%@ user=%@",
			   host, database, user);
	SampleWriteSnapshots(sheet.window, screenshots, @"postgres-connection-sheet");

	// Type the password and let the sheet's own Save & Refresh path validate and refresh.
	sheet.passwordField.stringValue = password;
	sheet.saveKeychainCheckbox.state = NSControlStateValueOff;
	// The first failure is still in the viewer; clear it so the wait below can see
	// the retry settle rather than the old error.
	[viewer setValue:nil forKey:@"lastRefreshError"];
	[sheet createDocumentAction:nil];
	BOOL refreshed = SampleWait(^BOOL{
		return document.headlessDocument.refreshed || viewer.lastRefreshError != nil;
	}, 60.0);
	if (!refreshed || viewer.lastRefreshError != nil) {
		SampleFail(@"PostgreSQL-Chinook.mad: refresh after the prompt failed: %@",
				   viewer.lastRefreshError.description ?: @"did not settle");
		return NO;
	}
	MADDataResult *result = [document resultForQuery:document.selectedQuery];
	if (result == nil || result.numberOfRows == 0) {
		SampleFail(@"PostgreSQL-Chinook.mad: refresh returned no rows");
		return NO;
	}
	SamplePass(@"PostgreSQL-Chinook.mad refreshed after the prompt: %lu rows",
			   (unsigned long)result.numberOfRows);
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
	SampleWriteSnapshots(wc.window, screenshots, @"postgres-viewer");
	SampleExportReportPDF(document.headlessDocument, document.selectedQuery, screenshots, @"postgres");
	SampleClearKeychainForConnection(connectionString);
	return YES;
}

/// The store has no password attribute at all; this rejects a document that smuggled
/// one into any of the credential strings anyway (a hand-edited sample or a regression
/// in the create chain).
static BOOL SampleDocumentStoresPassword(MADHeadlessDocument *document, NSString *password) {
	if (document == nil || password.length == 0) return NO;
	NSArray<NSString *> *attributes = @[@"driverID", @"dbname", @"host", @"server", @"domain", @"key", @"url"];
	for (RptqObject *credential in [document.storeContext objectsForEntity:@"RptqDatabaseCredentals"]) {
		for (NSString *attribute in attributes) {
			id value = [credential valueForKey:attribute];
			if ([value isKindOfClass:[NSString class]] && [value containsString:password]) return YES;
		}
	}
	return NO;
}

#pragma mark - Cross-database composition

static NSString *SampleTokenForSourceName(NSString *name) {
	if ([name isEqualToString:@"MySQL"]) return @"mysql";
	if ([name isEqualToString:@"PostgreSQL"]) return @"postgres";
	if ([name isEqualToString:@"SQL Server"]) return @"sqlserver";
	return name.lowercaseString;
}

static NSString *SamplePasswordForSourceName(NSString *name) {
	NSDictionary<NSString *, NSString *> *env = NSProcessInfo.processInfo.environment;
	if ([name isEqualToString:@"MySQL"]) return env[@"MAD_MYSQL_SAMPLE_PASSWORD"];
	if ([name isEqualToString:@"PostgreSQL"]) return env[@"MAD_PG_SAMPLE_PASSWORD"];
	if ([name isEqualToString:@"SQL Server"]) return env[@"MAD_TDS_SAMPLE_PASSWORD"];
	return nil;
}

static MADDatabaseConnection *SampleConnectionForSource(MADMacDocument *document, RptqQuery *source) {
	RptqDatabase *database = source.inDatabase;
	if (database == nil || database.ownedByUser == nil) return nil;
	return [MADDatabaseConnection newDatabaseConnection:database.ownedByUser documentURL:document.fileURL];
}

/// Refreshes a composed document through the viewer's real first-run path: the
/// refresh fails for want of credentials, the viewer asks the window controller to
/// walk the sources, and each sheet is answered here exactly as a person would --
/// after checking that the host, database and username are already filled in and the
/// password is blank.  Returns NO (with a SampleFail) on any deviation.
static BOOL SampleRefreshComposedWithPrompts(MADMacDocument *document,
											 MADMacWindowController *wc,
											 MADMacViewerViewController *viewer,
											 NSUInteger expectedRows,
											 NSString *label,
											 NSString *screenshots) {
	document.selectedQuery = document.rootQuery;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[viewer setValue:nil forKey:@"lastRefreshError"];
	[viewer refreshReportAction:nil];

	NSSet<NSString *> *expectedNames = [NSSet setWithArray:
		[[document sourceQueriesRequiringCredentials] valueForKey:@"name"]];
	NSMutableSet<NSValue *> *answeredSheets = [NSMutableSet set];
	NSMutableSet<NSString *> *answeredNames = [NSMutableSet set];
	NSMutableDictionary<NSString *, NSNumber *> *attempts = [NSMutableDictionary dictionary];
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:120.0];

	while (deadline.timeIntervalSinceNow > 0) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
		}
		MADMacConnectionWindowController *sheet = wc.activeConnectionSheetController;
		if (sheet != nil) {
			NSValue *key = [NSValue valueWithPointer:(__bridge const void *)sheet];
			if (![answeredSheets containsObject:key]) {
				[answeredSheets addObject:key];
				RptqQuery *target = sheet.targetQuery;
				NSString *name = target.name ?: @"";
				NSString *password = SamplePasswordForSourceName(name);
				if (target == nil || password.length == 0) {
					SampleFail(@"%@: a credential sheet asked for an unknown or unconfigured source '%@'",
							   label, name);
					return NO;
				}
				NSInteger attempt = attempts[name].integerValue;
				if (attempt >= 2) {
					SampleFail(@"%@: '%@' was asked for a password %ld times", label, name, (long)(attempt + 1));
					return NO;
				}
				attempts[name] = @(attempt + 1);

				// An attached sheet has populated controls; order it front so its fields
				// are laid out before they are read.
				[sheet.window makeKeyAndOrderFront:nil];
				[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];

				MADDatabaseConnection *conn = SampleConnectionForSource(document, target);
				id<MADConnectionsPropertiesProtocol> props = (id<MADConnectionsPropertiesProtocol>)conn;
				NSString *expectedHost = props.host ?: @"";
				NSString *expectedDatabase = props.database ?: @"";
				NSString *expectedUser = target.inDatabase.ownedByUser.domain ?: @"";
				NSString *shownPassword = sheet.passwordField.stringValue;
				BOOL prefillOK = [sheet.hostField.stringValue isEqualToString:expectedHost] &&
					[sheet.databaseField.stringValue isEqualToString:expectedDatabase] &&
					[sheet.usernameField.stringValue isEqualToString:expectedUser];
				// The first ask for a source must not carry a remembered password; a retry
				// may offer the one just tried.
				if (attempt == 0 && shownPassword.length != 0) prefillOK = NO;
				if (!prefillOK) {
					SampleFail(@"%@: '%@' prefilled host='%@' database='%@' user='%@' password='%lu chars'",
							   label, name, sheet.hostField.stringValue, sheet.databaseField.stringValue,
							   sheet.usernameField.stringValue, (unsigned long)shownPassword.length);
					return NO;
				}
				SamplePass(@"%@: asked for '%@' with %@ / %@ / %@ prefilled",
						   label, name, sheet.hostField.stringValue, sheet.databaseField.stringValue,
						   sheet.usernameField.stringValue);

				// One picture of the first-run prompt: host, database and username filled,
				// password empty.
				NSString *sheetPNG = [screenshots stringByAppendingPathComponent:
									  @"composition-cross-connection-sheet.png"];
				if (screenshots.length > 0 &&
					![[NSFileManager defaultManager] fileExistsAtPath:sheetPNG]) {
					SampleWriteSnapshots(sheet.window, screenshots, @"composition-cross-connection-sheet");
				}

				sheet.passwordField.stringValue = password;
				sheet.saveKeychainCheckbox.state = NSControlStateValueOff;
				[viewer setValue:nil forKey:@"lastRefreshError"];
				[answeredNames addObject:name];
				[sheet createDocumentAction:nil];
			}
		}

		MADDataResult *result = [document resultForQuery:document.rootQuery];
		if (document.headlessDocument.refreshed && result != nil) {
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
			if (viewer.lastRefreshError != nil) {
				SampleFail(@"%@: refresh: %@", label, viewer.lastRefreshError.description);
				return NO;
			}
			if (result.numberOfRows != expectedRows) {
				SampleFail(@"%@: %lu rows, expected %lu", label,
						   (unsigned long)result.numberOfRows, (unsigned long)expectedRows);
				return NO;
			}
			if (![answeredNames isEqualToSet:expectedNames]) {
				SampleFail(@"%@: prompted for %@, journaled %@", label,
						   expectedNames, answeredNames);
				return NO;
			}
			SamplePass(@"%@ refreshed through %lu source prompt(s): %lu rows",
					   label, (unsigned long)answeredNames.count,
					   (unsigned long)result.numberOfRows);
			return YES;
		}

		if (viewer.lastRefreshError != nil && sheet == nil) {
			SampleFail(@"%@: refresh: %@", label, viewer.lastRefreshError.description);
			return NO;
		}
	}
	SampleFail(@"%@: refresh did not settle", label);
	return NO;
}

static BOOL CheckCrossDatabaseComposition(NSURL *url, NSString *screenshots) {
	MADMacDocument *document = SampleOpenDocument(url, url.lastPathComponent);
	if (document == nil) return NO;
	MADMacWindowController *wc = document.windowControllers.firstObject;
	MADMacViewerViewController *viewer = wc.viewerViewController;

	if (!document.isComposed || [document allQueries].count < 3) {
		SampleFail(@"%@: composed=%d queries=%lu", url.lastPathComponent,
				   document.isComposed, (unsigned long)[document allQueries].count);
		return NO;
	}

	NSMutableArray<RptqQuery *> *sources = [NSMutableArray array];
	for (RptqQuery *query in [document allQueries]) {
		if (query != document.rootQuery) [sources addObject:query];
	}
	for (RptqQuery *source in sources) {
		if (SamplePasswordForSourceName(source.name).length == 0) {
			printf("SKIP  %@: set MAD_MYSQL_SAMPLE_PASSWORD / MAD_PG_SAMPLE_PASSWORD / MAD_TDS_SAMPLE_PASSWORD\n",
				   url.lastPathComponent.UTF8String);
			return YES;
		}
	}

	// A first run must not find a remembered credential for any of the three.
	for (RptqQuery *source in sources) {
		SampleClearKeychainForConnection(SampleConnectionForSource(document, source).connectionString);
	}

	if (!SampleRefreshComposedWithPrompts(document, wc, viewer, 5, url.lastPathComponent, screenshots)) {
		return NO;
	}
	if (wc.nodePickerPopup == nil || wc.nodePickerPopup.numberOfItems != (NSInteger)[document allQueries].count) {
		SampleFail(@"%@: node picker has %ld items", url.lastPathComponent,
				   (long)wc.nodePickerPopup.numberOfItems);
		return NO;
	}

	document.selectedQuery = document.rootQuery;
	[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	SampleWriteSnapshots(wc.window, screenshots, @"composition-cross-result-designer");
	[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	if (viewer.pdfView.document.pageCount < 1) {
		SampleFail(@"%@: the Result rendered no pages", url.lastPathComponent);
		return NO;
	}
	SamplePass(@"%@: the Result rendered %lu page(s)",
			   url.lastPathComponent, (unsigned long)viewer.pdfView.document.pageCount);
	SampleWriteSnapshots(wc.window, screenshots, @"composition-cross-result-viewer");
	SampleExportReportPDF(document.headlessDocument, document.rootQuery, screenshots, @"composition-cross-result");

	NSUInteger layoutSources = 0, gridSources = 0;
	for (RptqQuery *source in sources) {
		MADDataResult *result = [document resultForQuery:source];
		if (result == nil || result.numberOfRows != 5) {
			SampleFail(@"%@: source '%@' has %lu rows", url.lastPathComponent,
					   source.name, (unsigned long)result.numberOfRows);
			return NO;
		}
		document.selectedQuery = source;
		[wc switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
		NSUInteger fields = wc.designerViewController.displayedQueryFields.count;
		NSUInteger elements = SampleElementCount(document);
		BOOL hasLayout = elements > 0;
		if (fields != 3) {
			SampleFail(@"%@: source '%@' Designer shows %lu fields", url.lastPathComponent,
					   source.name, (unsigned long)fields);
			return NO;
		}
		NSString *token = SampleTokenForSourceName(source.name);
		SampleWriteSnapshots(wc.window, screenshots,
							 [NSString stringWithFormat:@"composition-cross-%@-designer", token]);

		[wc switchToWorkspaceTab:MADMacWorkspaceTabViewer];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
		BOOL grid = [viewer isShowingRowGrid];
		if (hasLayout) {
			layoutSources++;
			if (grid || viewer.pdfView.document.pageCount < 1) {
				SampleFail(@"%@: layout source '%@' showed %@", url.lastPathComponent,
						   source.name, grid ? @"a row grid" : @"no pages");
				return NO;
			}
			SampleWriteSnapshots(wc.window, screenshots,
								 [NSString stringWithFormat:@"composition-cross-%@-viewer", token]);
			SamplePass(@"%@: '%@' rendered its own %lu-page layout", url.lastPathComponent,
					   source.name, (unsigned long)viewer.pdfView.document.pageCount);
		} else {
			gridSources++;
			if (!grid || viewer.rowGridView.numberOfColumns < 3) {
				SampleFail(@"%@: layout-less source '%@' grid=%d columns=%lu", url.lastPathComponent,
						   source.name, grid, (unsigned long)viewer.rowGridView.numberOfColumns);
				return NO;
			}
			SampleWriteSnapshots(wc.window, screenshots,
								 [NSString stringWithFormat:@"composition-cross-%@-grid", token]);
			SamplePass(@"%@: '%@' showed a %lu-column, %lu-row grid", url.lastPathComponent,
					   source.name, (unsigned long)viewer.rowGridView.numberOfColumns,
					   (unsigned long)result.numberOfRows);
		}
	}
	if (layoutSources == 0 || gridSources == 0) {
		SampleFail(@"%@: layout sources=%lu grid sources=%lu", url.lastPathComponent,
				   (unsigned long)layoutSources, (unsigned long)gridSources);
		return NO;
	}

	document.selectedQuery = document.rootQuery;

	// Save and reopen: the graph, the layouts and the per-source prompt all survive.
	NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
						  [NSString stringWithFormat:@"mad-cross-reopen-%@.mad", NSUUID.UUID.UUIDString]];
	NSURL *savedURL = [NSURL fileURLWithPath:tempPath isDirectory:NO];
	NSError *saveError = nil;
	BOOL saved = [document writeToURL:savedURL
							   ofType:@"com.thomason.mad"
					 forSaveOperation:NSSaveOperation
				  originalContentsURL:url
								error:&saveError];
	if (!saved) {
		SampleFail(@"%@: save: %@", url.lastPathComponent, saveError.localizedDescription);
		return NO;
	}
	MADMacDocument *reopened = SampleOpenDocument(savedURL, @"reopened cross composition");
	if (reopened == nil) return NO;
	MADMacWindowController *reopenedWC = reopened.windowControllers.firstObject;
	MADMacViewerViewController *reopenedViewer = reopenedWC.viewerViewController;
	BOOL structureOK = reopened.isComposed &&
		[reopened allQueries].count == [document allQueries].count;
	NSUInteger reopenedLayouts = 0, reopenedGrids = 0;
	for (RptqQuery *reopenedSource in [reopened allQueries]) {
		if (reopenedSource == reopened.rootQuery) continue;
		SampleClearKeychainForConnection(SampleConnectionForSource(reopened, reopenedSource).connectionString);
		reopened.selectedQuery = reopenedSource;
		[reopenedWC switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
		if (SampleElementCount(reopened) > 0) reopenedLayouts++; else reopenedGrids++;
	}
	reopened.selectedQuery = reopened.rootQuery;
	structureOK = structureOK && reopenedLayouts == layoutSources && reopenedGrids == gridSources;
	structureOK = structureOK && SampleRefreshComposedWithPrompts(reopened, reopenedWC, reopenedViewer,
																  5, @"reopened cross composition",
																  screenshots);
	[[NSFileManager defaultManager] removeItemAtURL:savedURL error:NULL];
	if (!structureOK) {
		SampleFail(@"%@: save/reopen lost the composition or its refresh", url.lastPathComponent);
		return NO;
	}
	SamplePass(@"%@: saved, reopened and refreshed through every source", url.lastPathComponent);
	return YES;
}

#pragma mark - main

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		if (argc < 3) {
			fprintf(stderr, "usage: MADSampleCheck <samples-directory> <screenshots-directory>\n");
			return 1;
		}
		NSURL *samples = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]] isDirectory:YES];
		NSString *screenshots = [NSString stringWithUTF8String:argv[2]];
		[[NSFileManager defaultManager] createDirectoryAtPath:screenshots
								  withIntermediateDirectories:YES
												   attributes:nil
														error:NULL];

		(void)[NSApplication sharedApplication];
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
		[NSApp finishLaunching];
		[NSApp activateIgnoringOtherApps:YES];

		CheckStandard([samples URLByAppendingPathComponent:@"Chinook-Standard.mad" isDirectory:NO],
					  screenshots);
		CheckGrouped([samples URLByAppendingPathComponent:@"Chinook-Grouped.mad" isDirectory:NO],
					 screenshots);
		CheckComposition([samples URLByAppendingPathComponent:@"Chinook-Composition.mad" isDirectory:NO],
						 screenshots);
		CheckCopiedAndReopened(samples, screenshots);

		NSURL *postgres = [samples URLByAppendingPathComponent:@"PostgreSQL-Chinook.mad" isDirectory:NO];
		if ([[NSFileManager defaultManager] fileExistsAtPath:postgres.path]) {
			CheckPostgres(postgres, screenshots);
		}

		// A cross-database sample is any Composition-*.mad other than the Chinook
		// (single-file SQLite) one.  Its per-source prompts need the three passwords.
		NSArray<NSString *> *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:samples.path
																						  error:NULL];
		for (NSString *name in [entries sortedArrayUsingSelector:@selector(compare:)]) {
			if (![name hasPrefix:@"Composition-"] || ![name hasSuffix:@".mad"]) continue;
			if ([name isEqualToString:@"Chinook-Composition.mad"]) continue;
			CheckCrossDatabaseComposition([samples URLByAppendingPathComponent:name isDirectory:NO],
										  screenshots);
			break;
		}

		if (sFailures > 0) {
			fprintf(stderr, "%d sample check(s) failed\n", sFailures);
			return 1;
		}
		printf("all sample checks passed\n");
		return 0;
	}
}
