//
//  MADReportExporterHTMLFlow.h
//  MAD
//
//  `--format html-flow`: the same report as `html`, with the pages dropped and the
//  browser laying it out.  Sections become `<section>`s, rows `<tr>`s and elements
//  `<td>`s, so the file reflows to any window, a screen reader can follow it, and a
//  scraper or a model reads a table rather than a column of positioned boxes.
//
//  It reads the same page walk the facsimile and the PDF do, and then undoes exactly
//  one thing: what the walk repeats per page.  A page header and a page footer are the
//  same section on every page, so they are emitted once -- from the first page -- and
//  the pages after it contribute only what is new (the detail rows they carry).
//  Everything else is the walk's own order: report header, page header, groups,
//  detail, group footers, report footer.
//
//  Each cell carries `data-kind` (the element type the walk recorded) and its text;
//  the font and its traits ride on the row's style where the section's elements agree
//  on them.  It is a reading view, not the data contract: `--format json` is the
//  contract (MAD_DATA_OBJECT.md §6), and it has the columns, their types and the rows
//  as values rather than as laid-out text.
//

#ifndef MAD_MADReportExporterHTMLFlow_h
#define MAD_MADReportExporterHTMLFlow_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporting.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADReportExporterHTMLFlow : NSObject <MADReportExporting>
@end

NS_ASSUME_NONNULL_END

#endif
