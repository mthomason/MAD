//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExportWriter.h
//  MAD
//
//  The one place an exporter's bytes reach a destination, so a format that writes a
//  file and one that writes the standard output behave the same way (and a format
//  added later does not have to re-derive what "no --out" means).
//

#ifndef MAD_MADReportExportWriter_h
#define MAD_MADReportExportWriter_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADReportExportWriter : NSObject

/// Writes UTF-8 bytes for `string` to url, or to the standard output when url is nil.
+ (BOOL)writeString:(NSString *)string toURL:(nullable NSURL *)url error:(NSError * _Nullable __autoreleasing *)error;

/// The same for bytes a format produced itself.
+ (BOOL)writeData:(NSData *)data toURL:(nullable NSURL *)url error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
