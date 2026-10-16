//
//  MADCLIDocument.h
//  MAD Designer
//
//  Opens a document, refreshes it and -- on Apple -- exports it, with no interface.
//  The work is the application's own: the same MADOperationRefresh chain, the same
//  MADReportFormatter and MADPrintPageRenderer.  What is left out is only what needs
//  a window -- the share sheet, the spinner, the print dialog.
//
//  The document underneath is a MADocument on Apple, where the app's document class
//  exists, and a MADHeadlessDocument everywhere else (MAD_LINUX.md §9 Phase D); both
//  are read through MADDocumentDataProtocol, which is what the refresh chain takes
//  too, so the verbs above this file are the same on both.
//

#import <Foundation/Foundation.h>

#import <MAD/MADDocumentDataProtocol.h>

@class MADCredential;

NS_ASSUME_NONNULL_BEGIN

@interface MADCLIDocument : NSObject

/// Opens the document and waits for it to load.  On Apple that is a UIDocument,
/// which opens asynchronously on the main queue; headless it is a plain read.
+ (instancetype)documentWithURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)error;

@property (readonly, nonatomic, strong) id <MADDocumentDataProtocol> document;

/// Pages the last export laid out.  Zero before one has run.
@property (readonly, nonatomic, assign) NSUInteger pageCount;

/// The application's refresh chain, without the credentials fetch and without the
/// interface reload: initialize the data table, initialize the database and report
/// formatter, then execute the query into the row cache.
- (BOOL)refreshWithCredentials:(MADCredential *)credentials error:(NSError * _Nullable __autoreleasing *)error;

#if __APPLE__
/// Renders the report and writes a PDF.  Follows MADActivityItemProviderPdf
/// -writeToPdf:withViewController: step for step, minus the interface.  PDF is
/// Core Graphics, so this is the one verb that stays on Apple (MAD_LINUX.md §5.2).
///
/// `deterministic` pins the parts Core Graphics stamps from the clock -- the
/// creation and modification dates and the trailer identifier -- so that two runs
/// over an unchanged report produce identical bytes and a difference means a real
/// one.  See MADCLIPinPDFMetadata.
- (BOOL)writePDFToURL:(NSURL *)url deterministic:(BOOL)deterministic error:(NSError * _Nullable __autoreleasing *)error;
#endif

@end

NS_ASSUME_NONNULL_END
