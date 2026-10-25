//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterRegistry.m
//  MAD
//
//  See MADReportExporterRegistry.h for what this is and why it exists.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterRegistry.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>

#import <dispatch/dispatch.h>

// Registration runs from +load, before anything else can be holding the registry, so
// the table needs no lock: the writers are done before the first reader, and every
// reader only reads.
static NSMutableDictionary <NSString *, Class> *MADReportExporterTable(void) {
	static NSMutableDictionary <NSString *, Class> *table = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		table = [NSMutableDictionary dictionary];
	});
	return table;
}

@implementation MADReportExporterRegistry

+ (void)registerExporterClass:(Class <MADReportExporting>)exporterClass {
	if (exporterClass == Nil) return;

	NSString *key = [exporterClass formatName].lowercaseString;
	if (key.length == 0) return;

	Class registered = MADReportExporterTable()[key];
	if (registered == exporterClass) return;

	if (registered != Nil) {
		// Two exporters claiming one name is a link-time mistake the process cannot
		// recover from -- an export would produce one of them and never say which --
		// so it stops here, where the stack names the new one.
		[NSException raise: NSInternalInconsistencyException
					format: @"%@ and %@ both register as report export format '%@'",
							NSStringFromClass(registered), NSStringFromClass(exporterClass), key];
	}
	MADReportExporterTable()[key] = exporterClass;
}

+ (Class <MADReportExporting>)exporterClassForFormat:(NSString *)format {
	if (format.length == 0) return Nil;
	return MADReportExporterTable()[format.lowercaseString];
}

+ (NSArray <Class <MADReportExporting>> *)registeredExporterClasses {
	return [MADReportExporterTable().allValues sortedArrayUsingComparator: ^NSComparisonResult(Class a, Class b) {
		return [[a formatName] compare: [b formatName]];
	}];
}

+ (NSArray <NSString *> *)registeredFormatNames {
	NSMutableArray <NSString *> *names = [NSMutableArray arrayWithCapacity: MADReportExporterTable().count];
	for (Class <MADReportExporting> exporterClass in [self registeredExporterClasses]) {
		[names addObject: [exporterClass formatName]];
	}
	return names;
}

@end
