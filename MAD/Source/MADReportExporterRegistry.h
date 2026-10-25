//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterRegistry.h
//  MAD
//
//  The lookup half of the export seam: which formats a process has is what it links,
//  the same rule the driver registry follows (MADDatabaseDriverRegistry.h,
//  ROADMAP.md section 5.1).  Each exporter registers itself in +load; the CLI asks for
//  one by the name `--format` carries instead of naming the classes, so a new format
//  is a new class and nothing else.
//

#ifndef MAD_MADReportExporterRegistry_h
#define MAD_MADReportExporterRegistry_h

#import <Foundation/Foundation.h>

#import <MAD/MADReportExporting.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADReportExporterRegistry : NSObject

/// Registers an exporter for its own +formatName, called from the exporter's +load.
/// A second class claiming a name already taken is a programming error.
+ (void)registerExporterClass:(Class <MADReportExporting>)exporterClass;

/// The exporter registered for a format name (matched case-insensitively), or Nil
/// when nothing is.
+ (nullable Class <MADReportExporting>)exporterClassForFormat:(NSString *)format;

/// Every registered exporter, sorted by format name.
+ (NSArray <Class <MADReportExporting>> *)registeredExporterClasses;

/// The registered format names, sorted.
+ (NSArray <NSString *> *)registeredFormatNames;

@end

NS_ASSUME_NONNULL_END

#endif
