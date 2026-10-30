//
//  MADMacDocumentController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacDocumentController.h"
#import "MADMacAppDelegate.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface NSOpenPanel (MADMacNewDocumentButton)

- (void)_setShowNewDocumentButton:(BOOL)show;
- (BOOL)_showNewDocumentButton;
- (nullable NSButton *)_newDocumentButton;

@end

@interface MADMacDocumentController ()

@property (nonatomic, weak, readwrite, nullable) NSOpenPanel *activeOpenPanel;
@property (nonatomic, strong, nullable) NSButton *fallbackNewDocumentButton;

@end

@implementation MADMacDocumentController

+ (void)initialize {
	if (self == [MADMacDocumentController class]) {
		if ([NSBundle mainBundle].bundleIdentifier.length > 0) {
			[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"NSUseRemoteSavePanel": @NO}];
		}
	}
}

- (instancetype)init {
	if ([NSBundle mainBundle].bundleIdentifier.length > 0) {
		[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"NSUseRemoteSavePanel": @NO}];
	}
	return [super init];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
	if (item.action == @selector(newDocument:)) {
		return YES;
	}
	return [super validateUserInterfaceItem:item];
}

- (void)dismissOpenPanelIfNeeded {
	if (_activeOpenPanel != nil && _activeOpenPanel.isVisible) {	// Weak instance variable '_activeOpenPanel' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
		[_activeOpenPanel cancel:nil];
		_activeOpenPanel = nil;
	}
}

- (nullable NSButton *)newDocumentButtonForOpenPanel:(NSOpenPanel *)openPanel {
	if ([openPanel respondsToSelector:@selector(_newDocumentButton)]) {
		NSButton *button = [openPanel _newDocumentButton];
		if (button != nil) {
			return button;
		}
	}
	return _fallbackNewDocumentButton;
}

- (void)configureNewDocumentButtonForOpenPanel:(NSOpenPanel *)openPanel {
	openPanel.accessoryView = nil;
	openPanel.canCreateDirectories = NO;
	if ([openPanel respondsToSelector:@selector(_setShowNewDocumentButton:)]) {
		[openPanel _setShowNewDocumentButton:YES];
	}
	NSButton *newDocButton = nil;
	if ([openPanel respondsToSelector:@selector(_newDocumentButton)]) {
		newDocButton = [openPanel _newDocumentButton];
	}
	if (newDocButton == nil) {
		if (_fallbackNewDocumentButton == nil) {
			_fallbackNewDocumentButton = [NSButton buttonWithTitle:@"New Document"
															target:self
															action:@selector(newDocumentFromOpenPanel:)];
		}
		newDocButton = _fallbackNewDocumentButton;
	}
	newDocButton.title = @"New Document";
	newDocButton.bezelStyle = NSBezelStyleRounded;
	newDocButton.bezelColor = [NSColor controlAccentColor];
	if (@available(macOS 26.0, *)) {
		newDocButton.tintProminence = NSTintProminencePrimary;
	}
	newDocButton.target = self;
	newDocButton.action = @selector(newDocumentFromOpenPanel:);
	newDocButton.hidden = NO;
}

- (IBAction)openDocument:(nullable id)sender {
	if (_activeOpenPanel != nil && _activeOpenPanel.isVisible) {	// Weak instance variable '_activeOpenPanel' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
		[_activeOpenPanel makeKeyAndOrderFront:nil];
		return;
	}
	[super openDocument:sender];
}

- (IBAction)newDocument:(nullable id)sender {
	[self dismissOpenPanelIfNeeded];
	MADMacAppDelegate *appDelegate = (MADMacAppDelegate *)[NSApp delegate];
	if ([appDelegate respondsToSelector:@selector(newDocumentFromDatabase:)]) {
		[appDelegate newDocumentFromDatabase:sender];
	}
}

- (void)beginOpenPanel:(NSOpenPanel *)openPanel
			  forTypes:(nullable NSArray<NSString *> *)inTypes
	 completionHandler:(void (^)(NSInteger result))completionHandler {
	_activeOpenPanel = openPanel;

	openPanel.title = @"Open Report";
	openPanel.prompt = @"Open";
	openPanel.canChooseFiles = YES;
	openPanel.canChooseDirectories = NO;
	openPanel.allowsMultipleSelection = NO;
	openPanel.allowsOtherFileTypes = NO;

	UTType *madType = [UTType typeWithFilenameExtension:@"mad"];
	if (madType != nil) {
		openPanel.allowedContentTypes = @[madType];
	}

	[self configureNewDocumentButtonForOpenPanel:openPanel];

	__weak typeof(self) weakSelf = self;
	[super beginOpenPanel:openPanel
				 forTypes:inTypes
		completionHandler:^(NSInteger result) {
			if (weakSelf.activeOpenPanel == openPanel) {	// Weak variable 'weakSelf' is accessed multiple times in this block but may be unpredictably set to nil; assign to a strong variable to keep the object alive
				weakSelf.activeOpenPanel = nil;
			}
			completionHandler(result);
		}];

	[self configureNewDocumentButtonForOpenPanel:openPanel];
}

- (void)newDocumentFromOpenPanel:(id)sender {
	[self dismissOpenPanelIfNeeded];
	MADMacAppDelegate *appDelegate = (MADMacAppDelegate *)[NSApp delegate];
	if ([appDelegate respondsToSelector:@selector(newDocumentFromDatabase:)]) {
		[appDelegate newDocumentFromDatabase:sender];
	}
}

@end
