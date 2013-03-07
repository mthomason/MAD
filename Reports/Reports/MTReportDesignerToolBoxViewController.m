//
//  UIViewControllerToolBox.m
//  Reports
//
//  Created by Michael Thomason on 1/28/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerToolBoxViewController.h"
#import "AppDelegate.h"
#import "RptqDocumentObject+Extras.h"

@interface MTReportDesignerToolBoxViewController ()

@property (nonatomic, copy) NSSet *selectedObjectIds;

@property (retain, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemStyle;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemFontSelector;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemLayout;
@property (retain, nonatomic) IBOutlet UIView *backgroundView;
@property (retain, nonatomic) IBOutlet UIView *contentView;
@property (retain, nonatomic) IBOutlet UISegmentedControl *sceneSelector;

@property (nonatomic, retain) MTReportDesignerFontSettingsViewController *tableViewControllerTextLayoutSettings;
@property (nonatomic, retain) MTReportDesignerFontSelectorViewController *tableViewControllerFontSelector;

@end

@implementation MTReportDesignerToolBoxViewController

- (void)dealloc {
    [_selectedObjectIds release];
    [_navigationBar release];
    [_navigationItemStyle release];
    [_navigationItemFontSelector release];
    [_navigationItemLayout release];
    [_backgroundView release];
    [_contentView release];
    [_sceneSelector release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    
    MTReportDesignerFontSettingsViewController *reportDesignerFontSettingsViewController = [storyboard instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerStyle"];
    [reportDesignerFontSettingsViewController setDelegate:self];
    [self setTableViewControllerTextLayoutSettings:reportDesignerFontSettingsViewController];
    
    MTReportDesignerFontSelectorViewController *reportDesignerFontSelectorViewController = [storyboard instantiateViewControllerWithIdentifier:@"FontListSettingsTableViewController"];
    [reportDesignerFontSelectorViewController setDelegate:self];
    [self setTableViewControllerFontSelector:reportDesignerFontSelectorViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UINavigationItem *navigationItem = [[[self navigationBar] items] objectAtIndex:0];
    UIBarButtonItem *leftBarButtonItem = [navigationItem leftBarButtonItem];
    UISegmentedControl *segmentedControl = (UISegmentedControl *)[leftBarButtonItem customView];
    [segmentedControl addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self setSceneSelector:segmentedControl];
    [[[self tableViewControllerTextLayoutSettings] tableView] setBounds: [[self contentView] bounds]];
    [[[self tableViewControllerTextLayoutSettings] tableView] setFrame: CGRectMake(CGPointZero.x, CGPointZero.y, [[self contentView] bounds].size.width, [[self contentView] bounds].size.height)];
    [[self contentView] addSubview:[[self tableViewControllerTextLayoutSettings] view]];

}

- (CGFloat)contentHeight {
    CGFloat newHeight = 320.0000f;
    if ([[self sceneSelector] selectedSegmentIndex] == 0) {
        if ([[[[self navigationBar] items] lastObject]  isEqual:[self navigationItemFontSelector]]) {
            newHeight = 580.0000f;
        }
    } else if ([[self sceneSelector] selectedSegmentIndex] == 1) {
        newHeight = 540.0000f;
    }
    return newHeight;
}

- (void)showToolboxWithObjectIds:(NSSet *)objectIds {
    [self setSelectedObjectIds:objectIds];
    [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:objectIds];
}

- (void)hideToolbox {
    
}

- (IBAction)valueChanged:(id)sender {
    [sender setEnabled:NO];
    UIStoryboard *sbFontTableView = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    id newViewController = nil;
    if ([sender selectedSegmentIndex] == 0) {
        [[[[self navigationBar] items] lastObject] setTitle:NSLocalizedString(@"Style", @"Style")];
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerStyle"];
    } else  if ([sender selectedSegmentIndex] == 1) {
        [[[[self navigationBar] items] lastObject] setTitle:NSLocalizedString(@"Layout", @"Layout")];
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerLayout"];
    }
    [newViewController setSelectedDocumentObjects:[self selectedObjectIds]];
    [newViewController setDelegate:self];
    
    [[newViewController tableView] setBounds: [[self contentView] bounds]];
    [[newViewController tableView] setFrame: CGRectMake(CGPointZero.x, CGPointZero.y, [[self contentView] bounds].size.width, [[self contentView] bounds].size.height)];

    [UIView animateWithDuration:0.3000f animations:^{

        [[[self tableViewControllerTextLayoutSettings] view] removeFromSuperview];
        [self setTableViewControllerTextLayoutSettings:newViewController];
        [[self contentView] addSubview:[[self tableViewControllerTextLayoutSettings] view]];
    
    } completion:^(BOOL finished) {
    
        [[self delegate] heightChanged:[self contentHeight]];
        [sender setEnabled:YES];

    }];
}

#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
    [[self delegate] heightChanged:[self contentHeight]];
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
    [[self delegate] heightChanged:[self contentHeight]];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    BOOL shouldPopItem = NO;
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
        shouldPopItem = YES;
        
        CGRect offScreen = CGRectMake([[[self tableViewControllerFontSelector] tableView] frame].origin.x + [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].origin.y,
                                      [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].size.height);
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: [[self contentView] bounds]];
        
        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self tableViewControllerFontSelector] tableView] setFrame: offScreen];
        } completion:^(BOOL finished) {
            [[[self tableViewControllerFontSelector] tableView] removeFromSuperview];
        }];
    } else if ([item isEqual:[self navigationItemLayout]]) {
        
    } else if ([item isEqual:[self navigationItemStyle]]) {
        
    }
    
    return shouldPopItem;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    BOOL shouldPushItem = NO;
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
        shouldPushItem = YES;
        
        NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
        NSString *frontName = @"";
        for (NSManagedObjectID *objectId in [self selectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
            frontName = [documentObject fontname];
            break;
        }
        [[self tableViewControllerFontSelector] setSelectedFont:[MTFont fontWithFamilyName:frontName]];
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: [[self contentView] bounds]];
        [[[self tableViewControllerFontSelector] tableView] setBounds: [[self contentView] bounds]];
        CGRect newRect = [[[self tableViewControllerFontSelector] tableView] frame];
        CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [[self contentView] bounds].size.width, [[[self tableViewControllerFontSelector] tableView] frame].origin.y, [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].size.height);
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: newRectOffscreen];
        [[self contentView] addSubview:[[self tableViewControllerFontSelector] tableView]];
        
        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self tableViewControllerFontSelector] tableView] setFrame:newRect];
        } completion:^(BOOL finished) {
            
        }];
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    return shouldPushItem;
}

#pragma mark - UITableViewControllerFontSelectorDelegate

- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
    CGFloat currentPointSize = [[[[self tableViewControllerTextLayoutSettings] labelFontName] font] pointSize];
    
    MTFont *font = [[MTFont alloc] initWithFamilyName:fontName andPointSize:currentPointSize];
    
    
    [[self tableViewControllerTextLayoutSettings] chooseFont:font];
    
    [font release];

}

#pragma mark - FontSettingsTableViewControllerDelegate

- (void)fontSettingsTableViewControllerDidSelectFontList:(MTReportDesignerFontSettingsViewController *)controller {
    [[self navigationBar] pushNavigationItem:[self navigationItemFontSelector] animated:YES];
}

@end