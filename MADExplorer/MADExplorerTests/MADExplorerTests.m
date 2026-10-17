//
//  MADExplorerTests.m
//  MADExplorerTests
//
//  Created by Michael Thomason on 9/10/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIImage.h>
#import <MADExplorer/MADThumbnailView.h>

@interface MADExplorerTests : XCTestCase
@property (nonatomic, copy) NSString *directory;
@end

@implementation MADExplorerTests

- (void)setUp {
	[super setUp];
	self.directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:self.directory
							  withIntermediateDirectories:YES
											   attributes:nil
													error:NULL];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtPath:self.directory error:NULL];
	[super tearDown];
}

- (NSData *)pngDataOfSize:(CGSize)size {
	UIGraphicsBeginImageContextWithOptions(size, YES, 1.0);
	[[UIColor redColor] setFill];
	UIRectFill(CGRectMake(0.0, 0.0, size.width, size.height));
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return UIImagePNGRepresentation(image);
}

- (BOOL)waitForImageOfSize:(CGSize)size inView:(MADThumbnailView *)view {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:2.0];
	while ([deadline timeIntervalSinceNow] > 0.0) {
		if (CGSizeEqualToSize(view.image.size, size)) return YES;
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
	return NO;
}

// The page view rewrites the thumbnail at the same URL after every refresh.
// The view used to compare only the path, so it kept the old image (usually
// the blank placeholder it loaded before the first write).
- (void)testSamePathRewriteReloadsTheImage {
	// Not an @2x name: UIImage would load it at scale 2 and halve image.size,
	// which is what the test compares.
	NSString *path = [self.directory stringByAppendingPathComponent:@"Thumbnail.png"];
	NSURL *url = [NSURL fileURLWithPath:path];

	XCTAssertTrue([[self pngDataOfSize:CGSizeMake(2.0, 2.0)] writeToURL:url atomically:YES]);
	MADThumbnailView *view = [[MADThumbnailView alloc] initWithFrame:CGRectMake(0.0, 0.0, 8.0, 8.0)];
	view.thumbnailURL = url;
	XCTAssertTrue([self waitForImageOfSize:CGSizeMake(2.0, 2.0) inView:view],
				  @"the first thumbnail should load");

	XCTAssertTrue([[self pngDataOfSize:CGSizeMake(4.0, 4.0)] writeToURL:url atomically:YES]);
	// Make the modification date differ even where the filesystem timestamp is
	// coarse; that date is what distinguishes the rewrite from the first load.
	[[NSFileManager defaultManager] setAttributes:@{ NSFileModificationDate: [NSDate dateWithTimeIntervalSinceNow:10.0] }
									 ofItemAtPath:path
											error:NULL];
	view.thumbnailURL = url;
	XCTAssertTrue([self waitForImageOfSize:CGSizeMake(4.0, 4.0) inView:view],
				  @"re-setting the same path after the file changed must reload it");
}

@end
