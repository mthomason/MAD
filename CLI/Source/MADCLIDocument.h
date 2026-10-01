//
//  MADCLIDocument.h
//  MAD Designer
//
//  Opens a document, refreshes it and exports it, with no interface.  The work is
//  the application's own: the same MADocument, the same MADOperationRefresh chain,
//  the same MADReportFormatter and MADPrintPageRenderer.  What is left out is only
//  what needs a window -- the share sheet, the spinner, the print dialog.
//

#import <Foundation/Foundation.h>

@class MADocument, MADCredential;

@interface MADCLIDocument : NSObject

/// Opens the document and waits for it to load.  Runs on the main thread; UIDocument
/// and the document's managed object context both assume one.
+ (instancetype)documentWithURL:(NSURL *)url error:(NSError **)error;

@property (readonly, nonatomic, strong) MADocument *document;

/// Pages the last export laid out.  Zero before one has run.
@property (readonly, nonatomic, assign) NSUInteger pageCount;

/// The application's refresh chain, without the credentials fetch and without the
/// interface reload: initialize the data table, initialize the database and report
/// formatter, then execute the query into the row cache.
- (BOOL)refreshWithCredentials:(MADCredential *)credentials error:(NSError **)error;

/// Renders the report and writes a PDF.  Follows MADActivityItemProviderPdf
/// -writeToPdf:withViewController: step for step, minus the interface.
///
/// `deterministic` pins the parts Core Graphics stamps from the clock -- the
/// creation and modification dates and the trailer identifier -- so that two runs
/// over an unchanged report produce identical bytes and a difference means a real
/// one.  See MADCLIPinPDFMetadata.
- (BOOL)writePDFToURL:(NSURL *)url deterministic:(BOOL)deterministic error:(NSError **)error;

@end
