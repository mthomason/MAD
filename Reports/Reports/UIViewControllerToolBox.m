//
//  UIViewControllerToolBox.m
//  Reports
//
//  Created by Michael Thomason on 1/28/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerToolBox.h"
#import "AppDelegate.h"
#import "RptqDocumentObject+Extras.h"

@interface UIViewControllerToolBox ()

@property (nonatomic, copy) NSSet *selectedObjectIds;

@property (retain, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemStyle;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemFontSelector;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemLayout;
@property (retain, nonatomic) IBOutlet UIView *backgroundView;
@property (retain, nonatomic) IBOutlet UIView *contentView;
@property (retain, nonatomic) IBOutlet UISegmentedControl *sceneSelector;

@property (nonatomic, retain) UITableViewControllerFontSettings *tableViewControllerTextLayoutSettings;
@property (nonatomic, retain) UITableViewControllerFontSelector *tableViewControllerFontSelector;

@end

@implementation UIViewControllerToolBox

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    UIStoryboard *sbFontTableView = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    
    UITableViewControllerFontSettings *tb1 = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerStyle"];
    [tb1 setDelegate:self];
    [self setTableViewControllerTextLayoutSettings:tb1];
    
    UITableViewControllerFontSelector *tb2 = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontListSettingsTableViewController"];
    [tb2 setDelegate:self];
    [self setTableViewControllerFontSelector:tb2];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *navigationItem = [[[self navigationBar] items] objectAtIndex:0];
    UIBarButtonItem *leftBarButtonItem = [navigationItem leftBarButtonItem];
    UISegmentedControl *segmentedControl = (UISegmentedControl *)[leftBarButtonItem customView];
    [segmentedControl addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [[[self tableViewControllerTextLayoutSettings] tableView] setBounds: [[self contentView] bounds]];
    [[[self tableViewControllerTextLayoutSettings] tableView] setFrame: CGRectMake(CGPointZero.x, CGPointZero.y, [[self contentView] bounds].size.width, [[self contentView] bounds].size.height)];
    [[self contentView] addSubview:[[self tableViewControllerTextLayoutSettings] view]];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

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

- (void)showToolboxWithObjectIds:(NSSet *)objectIds {
    //[self setToolboxIsVisible:YES];
    //[[self informationButton] setEnabled: NO];
    [self setSelectedObjectIds:objectIds];
    [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:objectIds];
    
    
    //[[self view] layoutIfNeeded];
    //[UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: ^{
    //    [self setWantsFullScreenLayout:YES];
    //    [[self view] layoutIfNeeded];
    //} completion:nil];

}

- (void)hideToolbox {
    
}

- (IBAction)valueChanged:(id)sender {
    [sender setEnabled:NO];
    UIStoryboard *sbFontTableView = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    id newViewController = nil;
    if ([sender selectedSegmentIndex] == 0) {
        //newViewController = [[UITableViewControllerFontSettings alloc] initWithNibName:@"MTTableViewFontSettingsStyle" bundle:nil];
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerStyle"];
    } else  if ([sender selectedSegmentIndex] == 1) {
        //newViewController = [[UITableViewControllerFontSettings alloc] initWithNibName:@"MTTableViewFontSettingsLayout" bundle:nil];
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
  //      [newViewController retain];
//        [self setTableViewControllerTextLayoutSettings:newViewController];
        //[newViewController release];
        [sender setEnabled:YES];
    }];
}

#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
    
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

- (void)fontSettingsTableViewControllerDidSelectFontList:(UITableViewControllerFontSettings *)controller {
    [[self navigationBar] pushNavigationItem:[self navigationItemFontSelector] animated:YES];
}

@end