//
//  MADCLI.h
//  MAD Designer
//
//  Shared declarations for the `mad` command-line tool.  See MAD_CLI.md for the
//  command surface this implements.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, MADCLIExitCode) {
	MADCLIExitSuccess				= 0,
	MADCLIExitUsage					= 1,
	MADCLIExitBadDocument			= 2,
	MADCLIExitDatabaseUnreachable	= 3,
	MADCLIExitQueryFailed			= 4,
	MADCLIExitExportFailed			= 5,
};

/// The parsed command line.  One instance per run; nothing here touches a document.
@interface MADCLIInvocation : NSObject

@property (nonatomic, copy)   NSString *command;		// inspect, schema, query, refresh, export, write
@property (nonatomic, copy)   NSString *documentPath;	// the .mad file
@property (nonatomic, copy)   NSString *format;			// --format
@property (nonatomic, copy)   NSString *outPath;		// --out
@property (nonatomic, copy)   NSString *credentials;	// --credentials user:pass
@property (nonatomic, assign) BOOL noKeychain;			// --no-keychain
@property (nonatomic, assign) BOOL deterministic;		// --deterministic
@property (nonatomic, assign) BOOL reproducible;		// --reproducible (write)
@property (nonatomic, assign) BOOL verbose;				// --verbose
@property (nonatomic, assign) BOOL quiet;				// --quiet
@property (nonatomic, assign) NSInteger rows;			// --rows N, 0 means all

@property (readonly, nonatomic, copy) NSURL *documentURL;

@end

/// Parse argv.  Returns nil and fills `error` on a usage error.
MADCLIInvocation *MADCLIParseInvocation(NSArray <NSString *> *arguments, NSError **error);

/// Make a path from the command line absolute, relative to the caller's shell rather
/// than to this process.  See the note in MADCLI.m.
NSString *MADCLIResolveArgumentPath(NSString *path);

/// The verbs.  Each returns an exit code.
MADCLIExitCode MADCLIRunInspect(MADCLIInvocation *invocation);
MADCLIExitCode MADCLIRunSchema(MADCLIInvocation *invocation);
MADCLIExitCode MADCLIRunQuery(MADCLIInvocation *invocation);
MADCLIExitCode MADCLIRunRefresh(MADCLIInvocation *invocation);
MADCLIExitCode MADCLIRunExport(MADCLIInvocation *invocation);
MADCLIExitCode MADCLIRunWrite(MADCLIInvocation *invocation);

/// Logging that respects --quiet and --verbose.  Always to stderr, so stdout is
/// the result and nothing else.
void MADCLILog(MADCLIInvocation *invocation, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);
void MADCLIVerbose(MADCLIInvocation *invocation, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);
void MADCLIError(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/// An error's text for the terminal.  -localizedDescription alone is often just
/// "Error"; the drivers put the database's own words in the failure reason, and
/// printing only the description made a failed refresh read as a bare "Error".
NSString *MADCLIDescriptionForError(NSError *error);

/// Usage text, for stdout on --help and stderr on a usage error.
NSString *MADCLIUsageString(void);
