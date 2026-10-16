//
//  main.m
//  mad -- MAD Designer command line
//

#import <Foundation/Foundation.h>
#import "MADCLI.h"

int main(int argc, const char *argv[]) {
	@autoreleasepool {

		NSMutableArray <NSString *> *arguments = [NSMutableArray array];
		for (int i = 1; i < argc; i++) {
			[arguments addObject: [NSString stringWithUTF8String: argv[i]]];
		}

		NSError *parseError = nil;
		MADCLIInvocation *invocation = MADCLIParseInvocation(arguments, &parseError);
		if (invocation == nil) {
			MADCLIError(@"%@", parseError.localizedDescription);
			fputs("\n", stderr);
			fputs(MADCLIUsageString().UTF8String, stderr);
			return MADCLIExitUsage;
		}

		if ([invocation.command isEqualToString: @"help"]) {
			fputs(MADCLIUsageString().UTF8String, stdout);
			return MADCLIExitSuccess;
		}

		if ([invocation.command isEqualToString: @"inspect"])	return MADCLIRunInspect(invocation);
		if ([invocation.command isEqualToString: @"schema"])		return MADCLIRunSchema(invocation);
		if ([invocation.command isEqualToString: @"query"])		return MADCLIRunQuery(invocation);
		if ([invocation.command isEqualToString: @"refresh"])	return MADCLIRunRefresh(invocation);
		if ([invocation.command isEqualToString: @"export"])		return MADCLIRunExport(invocation);
		if ([invocation.command isEqualToString: @"write"])		return MADCLIRunWrite(invocation);

		return MADCLIExitUsage;
	}
}
