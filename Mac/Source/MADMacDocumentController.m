//
//  MADMacDocumentController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacDocumentController.h"
#import "MADMacAppDelegate.h"
#import "MADMacDocument.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static NSString * const MADDocumentUTIPrimary = @"com.everydayapps.productivity.mad";
static NSString * const MADDocumentUTILegacyMac = @"com.thomason.report.mad";
static NSString * const MADDocumentFilenameExtension = @"mad";

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

+ (NSArray<UTType *> *)allowedMadContentTypes {
	NSMutableOrderedSet<UTType *> *types = [[NSMutableOrderedSet alloc] init];

	NSArray<UTType *> *tagTypes = [UTType typesWithTag:MADDocumentFilenameExtension
											  tagClass:UTTagClassFilenameExtension
									  conformingToType:nil];
	if (tagTypes.count > 0) {
		[types addObjectsFromArray:tagTypes];
	}

	UTType *extType = [UTType typeWithFilenameExtension:MADDocumentFilenameExtension];
	if (extType != nil) {
		[types addObject:extType];
	}

	UTType *primaryType = [UTType typeWithIdentifier:MADDocumentUTIPrimary];
	if (primaryType != nil) {
		[types addObject:primaryType];
	}

	UTType *legacyMacType = [UTType typeWithIdentifier:MADDocumentUTILegacyMac];
	if (legacyMacType != nil) {
		[types addObject:legacyMacType];
	}

	return types.array;
}

+ (NSArray<NSString *> *)allowedMadTypeIdentifiers {
	NSMutableOrderedSet<NSString *> *identifiers = [[NSMutableOrderedSet alloc] init];
	for (UTType *type in [self allowedMadContentTypes]) {
		if (type.identifier.length > 0) {
			[identifiers addObject:type.identifier];
		}
	}
	[identifiers addObject:MADDocumentUTIPrimary];
	[identifiers addObject:MADDocumentUTILegacyMac];
	[identifiers addObject:MADDocumentFilenameExtension];
	return identifiers.array;
}

- (nullable NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)outError {
	if ([[url.pathExtension lowercaseString] isEqualToString:MADDocumentFilenameExtension]) {
		return MADDocumentUTIPrimary;
	}
	return [super typeForContentsOfURL:url error:outError];
}

- (nullable Class)documentClassForType:(NSString *)documentTypeName {
	Class docClass = [super documentClassForType:documentTypeName];
	if (docClass != Nil) {
		return docClass;
	}
	if ([documentTypeName isEqualToString:MADDocumentUTIPrimary] ||
		[documentTypeName isEqualToString:MADDocumentUTILegacyMac] ||
		[documentTypeName isEqualToString:@"Mobile Analytics Document"] ||
		[[documentTypeName lowercaseString] isEqualToString:MADDocumentFilenameExtension]) {
		return [MADMacDocument class];
	}
	UTType *utType = [UTType typeWithIdentifier:documentTypeName];
	if (utType != nil && [[utType.preferredFilenameExtension lowercaseString] isEqualToString:MADDocumentFilenameExtension]) {
		return [MADMacDocument class];
	}
	return Nil;
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
	if (item.action == @selector(newDocument:)) {
		return YES;
	}
	return [super validateUserInterfaceItem:item];
}

- (void)dismissOpenPanelIfNeeded {
	NSOpenPanel *panel = _activeOpenPanel;
	if (panel != nil && panel.isVisible) {
		[panel cancel:nil];
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
	NSOpenPanel *panel = _activeOpenPanel;
	if (panel != nil && panel.isVisible) {
		[panel makeKeyAndOrderFront:nil];
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

- (void)configureOpenPanelForMadDocuments:(NSOpenPanel *)openPanel {
	openPanel.title = @"Open Report";
	openPanel.prompt = @"Open";
	openPanel.canChooseFiles = YES;
	openPanel.canChooseDirectories = NO;
	openPanel.allowsMultipleSelection = NO;
	openPanel.allowsOtherFileTypes = NO;

	NSArray<UTType *> *madTypes = [[self class] allowedMadContentTypes];
	if (madTypes.count > 0) {
		openPanel.allowedContentTypes = madTypes;
	}

	[self configureNewDocumentButtonForOpenPanel:openPanel];
}

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel
					  forTypes:(nullable NSArray<NSString *> *) __unused types {
	_activeOpenPanel = openPanel;
	[self configureOpenPanelForMadDocuments:openPanel];
	NSArray<NSString *> *allowedTypeIdentifiers = [[self class] allowedMadTypeIdentifiers];
	NSInteger result = [super runModalOpenPanel:openPanel forTypes:allowedTypeIdentifiers];
	if (_activeOpenPanel == openPanel) {
		_activeOpenPanel = nil;
	}
	return result;
}

- (void)beginOpenPanel:(NSOpenPanel *)openPanel
			  forTypes:(nullable NSArray<NSString *> *) __unused inTypes
	 completionHandler:(void (^)(NSInteger result))completionHandler {
	_activeOpenPanel = openPanel;

	[self configureOpenPanelForMadDocuments:openPanel];
	NSArray<NSString *> *allowedTypeIdentifiers = [[self class] allowedMadTypeIdentifiers];

	__weak typeof(self) weakSelf = self;
	[super beginOpenPanel:openPanel
				 forTypes:allowedTypeIdentifiers
		completionHandler:^(NSInteger result) {
			typeof(self) strongSelf = weakSelf;
			if (strongSelf != nil && strongSelf.activeOpenPanel == openPanel) {
				strongSelf.activeOpenPanel = nil;
			}
			completionHandler(result);
		}];

	[self configureOpenPanelForMadDocuments:openPanel];
}

- (void)newDocumentFromOpenPanel:(id)sender {
	[self dismissOpenPanelIfNeeded];
	MADMacAppDelegate *appDelegate = (MADMacAppDelegate *)[NSApp delegate];
	if ([appDelegate respondsToSelector:@selector(newDocumentFromDatabase:)]) {
		[appDelegate newDocumentFromDatabase:sender];
	}
}

@end
