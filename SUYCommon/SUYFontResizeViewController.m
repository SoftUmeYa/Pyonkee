//
//  FontResizeViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/20.
//
//

#import "SUYFontResizeViewController.h"
#import "SUYScratchAppDelegate.h"

@interface SUYFontResizeViewController ()

@end

@implementation SUYFontResizeViewController

bool fontScaleUpdated = NO;
bool scriptsWereRunning = NO;

@synthesize slider;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SUYScratchAppDelegate *appDele = [self appDelegate];
    slider.value = [appDele getFontScaleIndex];
    scriptsWereRunning = [appDele scriptsAreRunning];
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [slider removeTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    if(fontScaleUpdated && scriptsWereRunning){
        [[self appDelegate] shoutGo];
    }
    [[self appDelegate].presentationSpace fixSizeOfSubViewsIfNeeded];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self removeFromParentViewController];
}


- (IBAction)sliderValueChanged:(UISlider *)sender {
    [slider setValue:((int)((slider.value + 0.5) / 1) * 1) animated:NO];
    [[self appDelegate] setFontScaleIndex: (int)slider.value];
    fontScaleUpdated = YES;
}

- (SUYScratchAppDelegate *)appDelegate
{
    SUYScratchAppDelegate *appDele = (SUYScratchAppDelegate*)[[UIApplication sharedApplication] delegate];
    return appDele;
}

@end
