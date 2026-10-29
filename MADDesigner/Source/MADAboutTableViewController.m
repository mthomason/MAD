//
//  MADAboutTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADAboutTableViewController.h"
#import "AppDelegate.h"
#import "MADGettingStartedTableViewController.h"
#import "MADTableViewCellBase.h"
#import "MADOperationPromptError.h"
#import "MADThemeManager.h"
#import <MADFoundation/madlog.h>
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MAD/MADConstants.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADBlockOperation.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADAlertController.h>
#import <MessageUI/MFMailComposeViewController.h>


static NSString * const MADIdentifierAboutViewController = @"MADIdentifierAboutViewController";

@implementation MADAcknowledgementsViewController

+ (NSAttributedString *)acknowledgementsAttributedText {
	UIFont *headingFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	UIFont *subheadingFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	UIFontDescriptor *boldSubDesc = [subheadingFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
	UIFont *boldSubheadingFont = boldSubDesc ? [UIFont fontWithDescriptor:boldSubDesc size:0.0] : subheadingFont;
	UIFont *bodyFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
	UIFont *monoFont = [UIFont monospacedSystemFontOfSize:11.0 weight:UIFontWeightRegular];

	UIColor *primaryColor = [UIColor labelColor];
	UIColor *secondaryColor = [UIColor secondaryLabelColor];

	NSDictionary *headingAttrs = @{
		NSFontAttributeName: headingFont,
		NSForegroundColorAttributeName: primaryColor
	};
	NSDictionary *componentTitleAttrs = @{
		NSFontAttributeName: boldSubheadingFont,
		NSForegroundColorAttributeName: primaryColor
	};
	NSDictionary *bodyAttrs = @{
		NSFontAttributeName: bodyFont,
		NSForegroundColorAttributeName: secondaryColor
	};
	NSDictionary *licenseBodyAttrs = @{
		NSFontAttributeName: monoFont,
		NSForegroundColorAttributeName: secondaryColor
	};

	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

	void (^appendSectionHeading)(NSString *) = ^(NSString *title) {
		if (result.length > 0) {
			[result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:bodyAttrs]];
		}
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[title stringByAppendingString:@"\n\n"] attributes:headingAttrs]];
	};

	void (^appendComponent)(NSString *, NSString *) = ^(NSString *name, NSString *details) {
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:name attributes:componentTitleAttrs]];
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:@" — " attributes:bodyAttrs]];
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[details stringByAppendingString:@"\n\n"] attributes:bodyAttrs]];
	};

	appendSectionHeading(NSLocalizedString(@"Open Source Components", @"Open Source Components"));

	[result appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"This application includes the following open source software:\n\n", @"Acknowledgements intro") attributes:bodyAttrs]];

	appendComponent(@"SQLite", @"Public domain. https://sqlite.org");
	appendComponent(@"zlib", @"© 1995–2026 Jean-loup Gailly and Mark Adler. Provided under the zlib License.");
	appendComponent(@"bzip2", @"© 1996–2019 Julian R Seward. Provided under the bzip2 License.");
	appendComponent(@"libpng", @"© 1995–2026 The PNG Reference Library Authors, © 2018–2026 Cosmin Truta and contributors. Provided under the PNG Reference Library License version 2.");
	appendComponent(@"libarchive", @"© 2003–2018 Tim Kientzle and contributors. Provided under the BSD 2-Clause License.");
	appendComponent(@"zint", @"© 2008–2025 Robin Stuart and contributors. Provided under the BSD 3-Clause License.");
	appendComponent(@"OpenSSL", @"© 1998–2026 The OpenSSL Project Authors. Provided under the Apache License 2.0. A copy of the license is included below.");
	appendComponent(@"PostgreSQL libpq", @"Portions © 1996–2026 PostgreSQL Global Development Group; Portions © 1994 The Regents of the University of California. Provided under the PostgreSQL License.");
	appendComponent(@"MariaDB Connector/C", @"© MariaDB Corporation Ab and contributors. This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. A copy of the license is included below, and the complete corresponding source is available at https://mariadb.org. To exercise your right to relink this application against a modified MariaDB Connector/C, contact mthomason@gmail.com to receive the object files and build materials needed to do so (available for at least three years from the last distribution of the application).");
	appendComponent(@"FreeTDS", @"© 1998–2015 Brian Bruns, Frediano Ziglio and contributors. This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. One installed header (sybdb.h) is modified as marked in the file. A copy of the license is included below, and the complete corresponding source is available at https://www.freetds.org. To exercise your right to relink this application against a modified FreeTDS, contact mthomason@gmail.com to receive the object files and build materials needed to do so (available for at least three years from the last distribution of the application).");
	appendComponent(@"asn1c runtime", @"© 2004, 2006 Lev Walkin. Redistribution and modification permitted subject to the BSD License.");
	appendComponent(@"pngquant rwpng", @"© 1998–2000 Greg Roelofs, © 2009–2014 Kornel Lesiński. Provided under the BSD 2-Clause License.");
	appendComponent(@"NSData+Base64", @"© 2009–2011 Matt Gallagher. Provided under a permissive license with copyright notice retained.");
	appendComponent(@"miniz", @"Rich Geldreich. Released into the public domain (Unlicense).");
	appendComponent(@"Font Awesome", @"© Dave Gandy. The font is provided under the SIL Open Font License 1.1.");
	appendComponent(@"Carbon Block", @"© 1999 Ray Larabie. Freeware, used under the terms accompanying the font.");

	NSArray<NSDictionary<NSString *, NSString *> *> *licenseFiles = @[
		@{ @"title": @"GNU Lesser General Public License v3.0 (FreeTDS, MariaDB Connector/C)", @"file": @"LGPL-3.0.txt" },
		@{ @"title": @"Apache License 2.0 (OpenSSL)", @"file": @"openssl-Apache-2.0.txt" },
		@{ @"title": @"libarchive — BSD 2-Clause License", @"file": @"libarchive-BSD-2-Clause.txt" },
		@{ @"title": @"zint — BSD 3-Clause License", @"file": @"zint-BSD-3-Clause.txt" },
		@{ @"title": @"PostgreSQL License (libpq)", @"file": @"postgres-LICENSE.txt" },
		@{ @"title": @"libpng — PNG Reference Library License v2", @"file": @"libpng-LICENSE.txt" },
		@{ @"title": @"bzip2 License", @"file": @"bzip2-LICENSE.txt" },
		@{ @"title": @"zlib License", @"file": @"zlib-LICENSE.txt" },
		@{ @"title": @"SQLite Blessing", @"file": @"sqlite3-LICENSE.md" },
		@{ @"title": @"asn1c Runtime — BSD License", @"file": @"asn1c-BSD.txt" },
		@{ @"title": @"pngquant rwpng — BSD 2-Clause License", @"file": @"rwpng-BSD-2-Clause.txt" },
		@{ @"title": @"Font Awesome — SIL Open Font License 1.1", @"file": @"FontAwesome-OFL-1.1.txt" },
	];

	NSBundle *bundle = [NSBundle mainBundle];
	BOOL addedLicenseSectionHeader = NO;
	for (NSDictionary<NSString *, NSString *> *entry in licenseFiles) {
		NSString *filename = entry[@"file"];
		NSString *path = [bundle pathForResource:filename ofType:nil inDirectory:@"Licenses"];
		if (!path) {
			path = [bundle pathForResource:filename ofType:nil];
		}
		if (!path) continue;

		NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		if (contents.length == 0) continue;

		if (!addedLicenseSectionHeader) {
			appendSectionHeading(NSLocalizedString(@"License Texts", @"License Texts"));
			addedLicenseSectionHeader = YES;
		}

		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[entry[@"title"] stringByAppendingString:@"\n\n"] attributes:componentTitleAttrs]];
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[contents stringByAppendingString:@"\n\n"] attributes:licenseBodyAttrs]];
	}

	return result;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = NSLocalizedString(@"Acknowledgements", @"Acknowledgements");
	self.view.backgroundColor = [UIColor systemBackgroundColor];
	self.preferredContentSize = CGSizeMake(360.0, 440.0);

	UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	textView.translatesAutoresizingMaskIntoConstraints = NO;
	textView.editable = NO;
	textView.selectable = YES;
	textView.backgroundColor = [UIColor systemBackgroundColor];
	textView.textContainerInset = UIEdgeInsetsMake(16.0, 16.0, 20.0, 16.0);
	textView.attributedText = [MADAcknowledgementsViewController acknowledgementsAttributedText];
	[self.view addSubview:textView];

	[NSLayoutConstraint activateConstraints:@[
		[textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
		[textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
	]];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}

@end

@interface MADAboutTableViewController () <MFMailComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@end

@implementation MADAboutTableViewController

+ (instancetype)newAboutTableViewController {
	return [[UIStoryboard storyboardWithName:@"MADAbout"
									  bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:MADIdentifierAboutViewController];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = NSLocalizedString(@"About", @"About");
	self.tableView.allowsSelection = YES;
	self.tableView.contentInset = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
	self.preferredContentSize = CGSizeMake(320.0, 265.0);
	self.tableView.backgroundColor = [UIColor systemBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	CGFloat contentHeight = self.tableView.contentSize.height + self.tableView.contentInset.top + self.tableView.contentInset.bottom;
	if (contentHeight > 100.0 && fabs(self.preferredContentSize.height - contentHeight) > 2.0) {
		self.preferredContentSize = CGSizeMake(320.0, ceil(contentHeight));
	}
}

#pragma mark - Exit

- (IBAction)unwindToAbout:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
				 fromViewController:(UIViewController *)fromViewController
							 sender:(nullable id)sender {
	return action == @selector(unwindToAbout:);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"MTSegueAboutGettingStarted"] ||
		[segue.identifier isEqualToString:@"MTSegueAboutSwipeNext"]) {
		((MADAboutTableViewController *)segue.destinationViewController).delegate = self.delegate;
	}
}

- (NSString *)versionText {
	return [[NSString alloc] initWithFormat:NSLocalizedString(@"v%@", @"v%@"), [AppDelegate bundleVersionShortString]];
}

- (NSString *)buildText {
	return [[NSString alloc] initWithFormat:NSLocalizedString(@"r%@", @"r%@"), [AppDelegate bundleGitCommitCount]];
}

- (IBAction)cancel:(id)sender {
	[self.delegate viewControllerDidCancel: self];
}

- (IBAction)done:(id)sender {
	[self.delegate viewControllerDidCancel: self];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError*)error {
	
	MADOperationQueue *operationQueue = [[MADOperationQueue alloc] init];
	MADOperationPromptError *operationErrorDisplay = [[MADOperationPromptError alloc] initWithError:error viewController:self];
	MADBlockOperation *finish = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock __unused completionBlock) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}];
	[operationErrorDisplay addDependency:finish];
	[operationQueue addOperation:operationErrorDisplay];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MADTableViewCellBase *cell = [tableView dequeueReusableCellWithIdentifier:@"MADTableViewCellAbout"];
	cell.frame = CGRectMake(CGPointZero.x, CGPointZero.y, self.tableView.bounds.size.width, tableView.estimatedRowHeight);
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.label.attributedText = nil;
	cell.label.text = nil;

	switch (indexPath.row) {
		case 0:
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
			cell.label.textColor = [MADColorEverydayApps newColorRed];
			cell.label.text = NSLocalizedString([AppDelegate bundleDisplayName], [AppDelegate bundleDisplayName]);
			cell.userInteractionEnabled = NO;
			cell.marginStyle = MADTableViewCellMarginStyleTop;
			break;

		case 1: {
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.text = [self versionText];
			cell.label.textColor = [UIColor labelColor];
			UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
			l.text = [self buildText];
			l.font = cell.label.font;
			l.textColor = [UIColor labelColor];
			[l sizeToFit];
			cell.accessoryView = l;
			cell.userInteractionEnabled = NO;
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
		}

		case 2:
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.text = NSLocalizedString([AppDelegate humanReadableCopyright], [AppDelegate humanReadableCopyright]);
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.userInteractionEnabled = NO;
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 3:
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
			cell.label.text = NSLocalizedString(@"Licensed under the MIT License. The names \"MAD\", \"MAD Designer\", and \"MAD Viewer\" and the application icons and artwork are not licensed under the MIT License; all rights in them are reserved by Michael Thomason.", @"MIT license and reserved brand/artwork notice");
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.userInteractionEnabled = NO;
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 4:
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.text = NSLocalizedString(@"Overview", @"Overview");
			cell.label.textColor = [UIColor labelColor];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			cell.userInteractionEnabled = YES;
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 5:
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.text = NSLocalizedString(@"Acknowledgements", @"Acknowledgements");
			cell.label.textColor = [UIColor labelColor];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			cell.userInteractionEnabled = YES;
			cell.marginStyle = MADTableViewCellMarginStyleBottom;
			break;

		default:
			break;
	}
	[cell setNeedsLayout];
	[cell setNeedsUpdateConstraints];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UIViewController *detailVC = nil;
	if (indexPath.row == 4) {
		detailVC = [[MADGettingStartedTableViewController alloc] initWithStyle:UITableViewStylePlain];
	} else if (indexPath.row == 5) {
		detailVC = [[MADAcknowledgementsViewController alloc] init];
	}
	if (detailVC != nil) {
		if (self.navigationController != nil) {
			[self.navigationController pushViewController:detailVC animated:YES];
		} else {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailVC];
			[self presentViewController:navController animated:YES completion:nil];
		}
	}
}

@end
