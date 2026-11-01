//
//  MADMacViewerViewController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacViewerViewController_h
#define MADMacViewerViewController_h

#import <Cocoa/Cocoa.h>
#import <MAD/MADPaperType.h>

@class MADMacDocument, PDFView;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacViewerViewController : NSViewController

@property (nonatomic, weak, nullable) MADMacDocument *document;
@property (nonatomic, assign) MTPaperType selectedPaperType;
@property (nonatomic, assign, readonly) MTPaperType renderedPaperType;
@property (nonatomic, assign, readonly) CGSize renderedPaperSize;
@property (nonatomic, assign) CGFloat zoomScale;

@property (nonatomic, strong, readonly) NSButton *refreshButton;
@property (nonatomic, strong, readonly) NSButton *connectionButton;
@property (nonatomic, strong, readonly) NSButton *exportButton;
@property (nonatomic, strong, readonly) NSButton *printButton;
@property (nonatomic, strong, readonly) NSPopUpButton *pageSizePopup;
@property (nonatomic, strong, readonly) NSPopUpButton *exportFormatPopup;
@property (nonatomic, strong, readonly) PDFView *pdfView;
@property (nonatomic, strong, readonly) NSView *statusBarView;
@property (nonatomic, strong, readonly) NSTextField *statusLabel;
@property (nonatomic, strong, readonly, nullable) NSError *lastRefreshError;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)reloadPreview;
- (void)refreshReportAction:(nullable id)sender;
- (void)exportReportAction:(nullable id)sender;
- (void)printReportAction:(nullable id)sender;
- (void)editDatabaseConnectionAction:(nullable id)sender;
- (void)locateMissingSQLiteDatabaseWithURL:(NSURL *)url
								completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion;

- (void)zoomInAction:(nullable id)sender;
- (void)zoomOutAction:(nullable id)sender;
- (void)zoomActualSizeAction:(nullable id)sender;
- (void)selectPaperType:(MTPaperType)paperType;
- (NSSavePanel *)configureExportSavePanel:(NSSavePanel *)panel;

+ (NSString *)statusMessageForPageCount:(NSUInteger)pageCount
							   rowCount:(NSUInteger)rowCount;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacViewerViewController_h */
