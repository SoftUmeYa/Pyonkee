//
//  SUYNavigationControllerViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/02/08.
//
//

#import "SUYNavigationController.h"

@interface SUYNavigationController ()

@end

@implementation SUYNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations{
    
    return [self.viewControllers.lastObject supportedInterfaceOrientations];
    
}

- (BOOL)shouldAutorotate{
    
    return [self.viewControllers.lastObject shouldAutorotate];
    
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    
    return [self.viewControllers.lastObject preferredInterfaceOrientationForPresentation];
    
}

@end
