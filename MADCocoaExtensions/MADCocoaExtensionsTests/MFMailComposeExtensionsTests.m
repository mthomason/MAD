//
//  MFMailComposeExtensionsTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MFMailComposeViewController (MADExtensions): the two mail-composer
//  factories.
//
//  The composer exposes no getters for the subject, body or attachments -- the real
//  API is write-only until presented -- so the factories are called on a recording
//  subclass whose setters capture what was written, and the presentation properties
//  are read back from the instance itself.  The composer is never presented.
//
//  MFMailComposeViewController -init returns nil when the device has no mail account
//  (the default state of a fresh simulator), so the whole class skips there -- the
//  same convention MADMySQLLiveTests and MADTdsClientLiveTests use for their absent
//  servers.
//

#import <XCTest/XCTest.h>

#import <MessageUI/MFMailComposeViewController.h>

#import <MADCocoaExtensions/MFMailComposeViewController+MADExtensions.h>

#pragma mark - Recording double

@interface MADRecordingMailComposer : MFMailComposeViewController
@property (nonatomic, copy) NSString *recordedSubject;
@property (nonatomic, copy) NSString *recordedBody;
@property (nonatomic, copy) NSData *recordedAttachmentData;
@property (nonatomic, copy) NSString *recordedAttachmentName;
@end

@implementation MADRecordingMailComposer

- (void)setSubject:(NSString *)subject {
	self.recordedSubject = subject;
	[super setSubject:subject];
}

- (void)setMessageBody:(NSString *)body isHTML:(BOOL)isHTML {
	self.recordedBody = body;
	[super setMessageBody:body isHTML:isHTML];
}

- (void)addAttachmentData:(NSData *)data mimeType:(NSString *)mimeType fileName:(NSString *)filename {
	self.recordedAttachmentData = data;
	self.recordedAttachmentName = filename;
	[super addAttachmentData:data mimeType:mimeType fileName:filename];
}

@end

@interface MFMailComposeExtensionsTests : XCTestCase

@property (nonatomic, copy) NSURL *attachmentURL;

@end

@implementation MFMailComposeExtensionsTests

- (void)setUp {
	[super setUp];
	XCTSkipIf(![MFMailComposeViewController canSendMail],
			  @"No mail account is configured; MFMailComposeViewController cannot be created.");
	self.attachmentURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:
													 [NSString stringWithFormat:@"MADMailTests-%@.mad", NSUUID.UUID.UUIDString]]];
	[[NSFileManager defaultManager] createFileAtPath:self.attachmentURL.path
											contents:[@"attachment" dataUsingEncoding:NSUTF8StringEncoding]
										  attributes:nil];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.attachmentURL error:NULL];
	[super tearDown];
}

#pragma mark - Title and body

- (void)testComposeWithTitleAndBody {
	MADRecordingMailComposer *composer;
	composer = [MADRecordingMailComposer ma_newMailComposeViewControllerWithTitle:@"A Title"
																			 body:@"A Body"
															   userInterfaceIdiom:UIUserInterfaceIdiomPhone];

	XCTAssertNotNil(composer);
	XCTAssertEqualObjects(composer.recordedSubject, @"A Title");
	XCTAssertEqualObjects(composer.recordedBody, @"A Body");
}

- (void)testComposeOnIPadUsesTheFormSheet {
	MADRecordingMailComposer *composer;
	composer = [MADRecordingMailComposer ma_newMailComposeViewControllerWithTitle:@"A Title"
																			 body:@"A Body"
															   userInterfaceIdiom:UIUserInterfaceIdiomPad];

	XCTAssertEqual(composer.modalPresentationStyle, UIModalPresentationFormSheet);
	XCTAssertEqual(composer.modalTransitionStyle, UIModalTransitionStyleFlipHorizontal);
	XCTAssertTrue(composer.providesPresentationContextTransitionStyle);
	XCTAssertFalse(composer.modalInPresentation);
}

- (void)testComposeOnIPhoneLeavesThePresentationDefault {
	MADRecordingMailComposer *composer;
	composer = [MADRecordingMailComposer ma_newMailComposeViewControllerWithTitle:@"A Title"
																			 body:@"A Body"
															   userInterfaceIdiom:UIUserInterfaceIdiomPhone];
	MADRecordingMailComposer *fresh = [[MADRecordingMailComposer alloc] init];

	// The iPhone path touches none of the presentation properties, so they keep the
	// composer's own defaults (Automatic on current iOS, not FormSheet).
	XCTAssertEqual(composer.modalPresentationStyle, fresh.modalPresentationStyle);
	XCTAssertNotEqual(composer.modalPresentationStyle, UIModalPresentationFormSheet);
}

#pragma mark - Attachment

- (void)testComposeWithAttachmentNamesAndAttachesTheFile {
	MADRecordingMailComposer *composer;
	composer = [MADRecordingMailComposer ma_newMailComposeViewControllerWithBody:@"Body"
																	  attachment:self.attachmentURL
																		mimeType:@"application/octet-stream"
															  userInterfaceIdiom:UIUserInterfaceIdiomPhone];

	XCTAssertNotNil(composer);
	// The subject is built from the attachment's filename.
	XCTAssertTrue([composer.recordedSubject containsString:self.attachmentURL.lastPathComponent]);
	XCTAssertEqualObjects(composer.recordedBody, @"Body");
	// The attachment's bytes were read from the file and handed to the composer.
	XCTAssertEqualObjects(composer.recordedAttachmentName, self.attachmentURL.lastPathComponent);
	NSData *expected = [@"attachment" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects(composer.recordedAttachmentData, expected);
}

@end
