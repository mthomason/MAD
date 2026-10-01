//
//  MADCLIUnimplemented.m
//  MAD Designer
//
//  The verbs that are not written yet.  This file goes away as each one lands.  It
//  exists so the tool builds and runs while the data path is being brought up, which
//  is the whole point of building the CLI first.
//

#import "MADCLI.h"

MADCLIExitCode MADCLIRunSchema(MADCLIInvocation *invocation) {
	MADCLIError(@"mad schema: not implemented yet.");
	return MADCLIExitUsage;
}
