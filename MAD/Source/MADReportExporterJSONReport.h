//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterJSONReport.h
//  MAD
//
//  `--format json-report`: everything `json` writes, plus a "report" member holding
//  the rendered report -- its pages, each page's sections in draw order, each
//  section's rows, and each row's lines with the element kind, its frame and its
//  resolved text.  The user's choice, 2026-10-16 (MAD_LINUX.md §10.1): the data half
//  is what analysis wants, and the report half is what testing and a renderer want,
//  so they are one schema with the second as an extra member.
//
//    "report": {
//      "pages": [
//        { "index": 0,
//          "sections": [
//            { "type": "ReportHeader", "groupLevel": 0, "visible": true,
//              "rows": [ { "lines": [
//                  { "kind": "LabelStatic", "frame": [0, 0, 200, 20], "text": "Sales Report" } ] } ] } ] } ] }
//
//  The structure is the walk's own: it reads exactly the pages the PDF export draws
//  (MADReportPageBuilder), minus the drawing, so what this member says and what a page
//  shows cannot drift apart.  The render half is compiled on both platforms
//  (MAD_LINUX.md §9 Phase E), so the format runs wherever the data half does; a
//  document that cannot render is refused rather than served the data half under this
//  name.
//

#ifndef MAD_MADReportExporterJSONReport_h
#define MAD_MADReportExporterJSONReport_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporterJSON.h>

@interface MADReportExporterJSONReport : MADReportExporterJSON
@end

#endif
