//
//  MADCLI.m
//  MAD Designer
//

#import "MADCLI.h"

#import <MAD/MADReportExporterRegistry.h>

static NSString * const MADCLICommandInspect	= @"inspect";
static NSString * const MADCLICommandSchema		= @"schema";
static NSString * const MADCLICommandQuery		= @"query";
static NSString * const MADCLICommandRefresh	= @"refresh";
static NSString * const MADCLICommandExport		= @"export";
static NSString * const MADCLICommandWrite		= @"write";

static NSError *MADCLIUsageError(NSString *message) {
	return [NSError errorWithDomain: @"MADCLI"
							   code: MADCLIExitUsage
						   userInfo: @{ NSLocalizedDescriptionKey: message }];
}

/// A relative path is relative to the caller's shell, not to this process: the tool
/// runs inside the simulator, whose working directory is a container on the far side
/// of the host.  build.sh passes the shell's directory in MAD_HOST_CWD.
NSString *MADCLIResolveArgumentPath(NSString *path) {
	if (path.length == 0 || [path isAbsolutePath]) return path;
	NSString *workingDirectory = [NSProcessInfo processInfo].environment[@"MAD_HOST_CWD"];
	if (workingDirectory.length == 0) {
		workingDirectory = [NSFileManager defaultManager].currentDirectoryPath;
	}
	return [workingDirectory stringByAppendingPathComponent: path];
}

@implementation MADCLIInvocation

- (NSURL *)documentURL {
	return self.documentPath.length > 0 ? [NSURL fileURLWithPath: MADCLIResolveArgumentPath(self.documentPath)] : nil;
}

@end

#pragma mark -

MADCLIInvocation *MADCLIParseInvocation(NSArray <NSString *> *arguments, NSError **error) {

	MADCLIInvocation *invocation = [[MADCLIInvocation alloc] init];
	NSMutableArray <NSString *> *positional = [NSMutableArray array];

	NSUInteger index = 0;
	while (index < arguments.count) {
		NSString *argument = arguments[index];

		if ([argument isEqualToString: @"--verbose"]) {
			invocation.verbose = YES;
		} else if ([argument isEqualToString: @"--quiet"]) {
			invocation.quiet = YES;
		} else if ([argument isEqualToString: @"--no-keychain"]) {
			invocation.noKeychain = YES;
		} else if ([argument isEqualToString: @"--deterministic"]) {
			invocation.deterministic = YES;
		} else if ([argument isEqualToString: @"--reproducible"]) {
			invocation.reproducible = YES;
		} else if ([argument hasPrefix: @"--"]) {

			// Every remaining option takes a value.  A missing value is a usage error
			// rather than a silent default, because the only caller is a script.
			NSString *name = [argument substringFromIndex: 2];
			NSString *value = nil;
			NSRange equals = [name rangeOfString: @"="];
			if (equals.location != NSNotFound) {
				value = [name substringFromIndex: equals.location + 1];
				name = [name substringToIndex: equals.location];
			} else {
				index++;
				if (index >= arguments.count) {
					if (error) *error = MADCLIUsageError([NSString stringWithFormat: @"Option --%@ needs a value.", name]);
					return nil;
				}
				value = arguments[index];
			}

			if ([name isEqualToString: @"format"]) {
				invocation.format = value;
			} else if ([name isEqualToString: @"out"]) {
				invocation.outPath = value;
			} else if ([name isEqualToString: @"credentials"]) {
				invocation.credentials = value;
			} else if ([name isEqualToString: @"rows"]) {
				NSScanner *scanner = [NSScanner scannerWithString: value];
				long long rows = 0;
				if (![scanner scanLongLong: &rows] || !scanner.isAtEnd || rows < 0) {
					if (error) *error = MADCLIUsageError([NSString stringWithFormat: @"--rows needs a non-negative number, got '%@'.", value]);
					return nil;
				}
				invocation.rows = (NSInteger)rows;
			} else {
				if (error) *error = MADCLIUsageError([NSString stringWithFormat: @"Unknown option --%@.", argument]);
				return nil;
			}
		} else {
			[positional addObject: argument];
		}
		index++;
	}

	if (positional.count == 0) {
		if (error) *error = MADCLIUsageError(@"No command given.");
		return nil;
	}
	invocation.command = positional[0];

	if ([invocation.command isEqualToString: @"help"] ||
		[invocation.command isEqualToString: @"--help"] ||
		[invocation.command isEqualToString: @"-h"]) {
		invocation.command = @"help";
		return invocation;
	}

	if (positional.count < 2) {
		if (error) *error = MADCLIUsageError([NSString stringWithFormat: @"mad %@ needs a document.", invocation.command]);
		return nil;
	}
	invocation.documentPath = positional[1];

	static NSSet <NSString *> *known = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		known = [NSSet setWithObjects: MADCLICommandInspect, MADCLICommandSchema, MADCLICommandQuery,
									   MADCLICommandRefresh, MADCLICommandExport, MADCLICommandWrite, nil];
	});
	if (![known containsObject: invocation.command]) {
		if (error) *error = MADCLIUsageError([NSString stringWithFormat: @"Unknown command '%@'.", invocation.command]);
		return nil;
	}

	return invocation;
}

NSString *MADCLIUsageString(void) {
	// The format list is the export seam's, so a format added as a new class appears
	// here without this string being edited (MADReportExporterRegistry.h).  It is
	// every registered format, pdf included -- it is an exporter now, and a build
	// that cannot produce it says so when it is asked for.
	NSArray <NSString *> *formats = [MADReportExporterRegistry registeredFormatNames];

	NSMutableString *usage = [[NSMutableString alloc] init];
	[usage appendFormat:
			@"mad -- MAD Designer command line\n"
			"\n"
			"  mad <command> [options] <document.mad>\n"
			"\n"
			"Commands:\n"
			"  inspect   read the container and report what is in it\n"
			"  schema    print the database schema the document was built against\n"
			"  query     print the SQL the document's query generates\n"
			"  refresh   run the query and fill the row cache\n"
			"  export    render the report and write it out\n"
			"  write     write the document out as a .mad (a copy; --out is required)\n"
			"\n"
			"Options:\n"
			"  --format <name>          output format (export: %@)\n"
			"  --out <path>             output path; '-' or absent is stdout\n",
			[formats componentsJoinedByString: @", "]];
	[usage appendString:
			@"  --credentials user:pass  source-database credentials\n"
			@"  --no-keychain            never read the keychain\n"
			@"  --deterministic          pin the export's dates and identifier, so two\n"
			@"                           runs over unchanged data are byte-identical\n"
			@"  --reproducible           pin the .mad archive's inputs -- time, ownership,\n"
			@"                           member order -- so the same document writes the\n"
			@"                           same bytes anywhere (write)\n"
			@"  --rows N                 stop after N rows (refresh)\n"
			@"  --verbose                log the data path at each stage\n"
			@"  --quiet                  suppress everything but the result\n"
			@"\n"
			@"Exit codes: 0 success, 1 usage, 2 bad document, 3 database unreachable,\n"
			@"            4 query failed, 5 export failed\n"];
	return usage;
}

#pragma mark - Logging

void MADCLILog(MADCLIInvocation *invocation, NSString *format, ...) {
	if (invocation.quiet) return;
	va_list arguments;
	va_start(arguments, format);
	NSString *message = [[NSString alloc] initWithFormat: format arguments: arguments];
	va_end(arguments);
	fprintf(stderr, "%s\n", message.UTF8String);
}

void MADCLIVerbose(MADCLIInvocation *invocation, NSString *format, ...) {
	if (!invocation.verbose || invocation.quiet) return;
	va_list arguments;
	va_start(arguments, format);
	NSString *message = [[NSString alloc] initWithFormat: format arguments: arguments];
	va_end(arguments);
	fprintf(stderr, "%s\n", message.UTF8String);
}

void MADCLIError(NSString *format, ...) {
	va_list arguments;
	va_start(arguments, format);
	NSString *message = [[NSString alloc] initWithFormat: format arguments: arguments];
	va_end(arguments);
	fprintf(stderr, "%s\n", message.UTF8String);
}

NSString *MADCLIDescriptionForError(NSError *error) {
	if (error == nil) return @"no error given";
	NSString *description = error.localizedDescription;
	NSString *reason = error.localizedFailureReason;
	if (reason.length == 0 || [reason isEqualToString: description]) {
		return description.length > 0 ? description : @"Error";
	}
	return [NSString stringWithFormat: @"%@: %@", description, reason];
}
