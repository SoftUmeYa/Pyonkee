//
//  SUYWebViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/01.
//
//

#import "SUYWebViewController.h"

@interface SUYWebViewController ()

@end

@implementation SUYWebViewController

@synthesize webView, gestureRecognizer, initialUrl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

#pragma mark ViewCallbacks

- (void)viewDidLoad
{
    [super viewDidLoad];
    webView.delegate = self;
    webView.scalesPageToFit = YES;
    LgInfo(@"LOCAL URL is %@", initialUrl);
    [self loadUrl];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //Code for dissmissing this viewController by clicking outside it
    gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [gestureRecognizer setNumberOfTapsRequired:1];
    gestureRecognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:gestureRecognizer];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.view.superview.bounds = CGRectMake(0, 0, 960, 720);
    self.view.superview.alpha = 1.0;
}

#pragma mark Private

- (void)loadUrl {
    NSURL *url = [NSURL fileURLWithPath: initialUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [sender locationInView:nil];
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil])
        {
            [self close: nil];
        }
    }
}

#pragma mark WebViewDelegateCallback

- (void)webViewDidStartLoad:(UIWebView*)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}


- (void)webViewDidFinishLoad:(UIWebView*)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark Releasing

- (IBAction)close:(UIButton*)sender
{
    [self.view.window removeGestureRecognizer:gestureRecognizer];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self close: nil];
}

@end
