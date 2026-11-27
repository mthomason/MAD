//
//  MADMacTipBar.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacTipBar.h"

NSNotificationName const MADMacTipBarDidResetNotification = @"MADMacTipBarDidResetNotification";

static NSString *MADTipDefaultsKey(NSString *identifier) {
	return [NSString stringWithFormat:@"MADMacTip.%@", identifier];
}

@interface MADMacTipBar ()
@property (nonatomic, copy, readwrite) NSString *tipIdentifier;
@property (nonatomic, strong, readwrite) NSTextField *textLabel;
@property (nonatomic, strong, readwrite) NSButton *dismissButton;
@property (nonatomic, assign, readwrite, getter=isDismissed) BOOL dismissed;
@end

@implementation MADMacTipBar

+ (instancetype)tipBarWithIdentifier:(NSString *)identifier text:(NSString *)text {
	return [[self alloc] initWithTipIdentifier:identifier text:text];
}

- (instancetype)initWithTipIdentifier:(NSString *)identifier text:(NSString *)text {
	if (self = [super initWithFrame:NSMakeRect(0.0, 0.0, 640.0, 30.0)]) {
		_tipIdentifier = [identifier copy];
		self.wantsLayer = YES;
		self.layer.backgroundColor = [NSColor controlBackgroundColor].CGColor;

		NSImageView *icon = [[NSImageView alloc] initWithFrame:NSZeroRect];
		if (@available(macOS 11.0, *)) {
			icon.image = [NSImage imageWithSystemSymbolName:@"lightbulb"
								  accessibilityDescription:NSLocalizedString(@"Tip", @"Accessibility description for the tip icon.")];
			icon.contentTintColor = [NSColor secondaryLabelColor];
		}
		icon.translatesAutoresizingMaskIntoConstraints = NO;
		[icon setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
		[icon setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];

		_textLabel = [NSTextField wrappingLabelWithString:text];
		_textLabel.font = [NSFont systemFontOfSize:11.5];
		_textLabel.textColor = [NSColor secondaryLabelColor];
		_textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		_textLabel.maximumNumberOfLines = 2;
		_textLabel.accessibilityLabel = text;
		_textLabel.translatesAutoresizingMaskIntoConstraints = NO;

		_dismissButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"xmark.circle.fill"
															accessibilityDescription:NSLocalizedString(@"Dismiss Tip", @"Accessibility description for the tip's close button.")]
											target:self
											action:@selector(dismissTip:)];
		_dismissButton.bordered = NO;
		_dismissButton.imagePosition = NSImageOnly;
		_dismissButton.contentTintColor = [NSColor tertiaryLabelColor];
		_dismissButton.toolTip = NSLocalizedString(@"Dismiss Tip", @"Tooltip for the tip bar's close button.");
		_dismissButton.accessibilityLabel = NSLocalizedString(@"Dismiss Tip", @"Accessibility label for the tip bar's close button.");
		_dismissButton.translatesAutoresizingMaskIntoConstraints = NO;

		NSBox *bottomLine = [[NSBox alloc] initWithFrame:NSZeroRect];
		bottomLine.boxType = NSBoxSeparator;
		bottomLine.translatesAutoresizingMaskIntoConstraints = NO;

		[self addSubview:icon];
		[self addSubview:_textLabel];
		[self addSubview:_dismissButton];
		[self addSubview:bottomLine];

		[NSLayoutConstraint activateConstraints:@[
			[icon.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12.0],
			[icon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
			[icon.widthAnchor constraintEqualToConstant:14.0],
			[icon.heightAnchor constraintEqualToConstant:14.0],

			[_textLabel.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:7.0],
			[_textLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
			[_textLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_dismissButton.leadingAnchor constant:-8.0],

			[_dismissButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10.0],
			[_dismissButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
			[_dismissButton.widthAnchor constraintEqualToConstant:18.0],
			[_dismissButton.heightAnchor constraintEqualToConstant:18.0],

			[bottomLine.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
			[bottomLine.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
			[bottomLine.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
		]];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(tipsDidReset:)
													 name:MADMacTipBarDidResetNotification
												   object:nil];
		[self showIfNeeded];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showIfNeeded {
	self.dismissed = [[NSUserDefaults standardUserDefaults] boolForKey:MADTipDefaultsKey(self.tipIdentifier)];
	self.hidden = self.dismissed;
}

- (void)dismissTip:(nullable id) __unused sender {
	self.dismissed = YES;
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:MADTipDefaultsKey(self.tipIdentifier)];
	self.hidden = YES;
	if (self.superview != nil) {
		[self.superview setNeedsLayout:YES];
	}
}

- (void)tipsDidReset:(NSNotification *) __unused note {
	[self showIfNeeded];
}

@end
