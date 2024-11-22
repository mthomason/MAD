//
//  MADOperationCreateDocumentAddConnection.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADCreateDocumentOperationImportSchema_h
#define MAD_Designer_MADCreateDocumentOperationImportSchema_h

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationPromptErrorProtocol.h>
#import <MADFoundation/MADOperationTestResults.h>

@class MADDatabaseConnection;

@protocol MADOperationCreateDocumentImportSchemaProtocol <NSObject>
	- (void)updateImportProgressWithMessage:(NSString *)message progress:(float)progress;
@end

@interface MADOperationCreateDocumentImportSchema : MADOperation
	<MADOperationPromptErrorProtocol, MADOperationTestResults>
	- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection NS_DESIGNATED_INITIALIZER;
	@property (nonatomic, weak) id <MADOperationCreateDocumentImportSchemaProtocol> parentOperation;
	@property (nonatomic, assign, readonly, getter=isSuccess) BOOL success;

@end

#endif
