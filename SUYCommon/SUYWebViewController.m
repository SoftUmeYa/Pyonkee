//
//  SUYWebViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/01.
//
//

#import "SUYWebViewController.h"
#import "SUYUtils.h"

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

- (void)loadView
{
    [super loadView];
    
    WKWebViewConfiguration *config = [self createConfig];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:self.webView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1.0
                                                              constant:0],
                                [NSLayoutConstraint constraintWithItem:self.webView
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:1.0
                                                              constant:0]
                                ]];
    
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    [self.view sendSubviewToBack:self.webView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    LgInfo(@"LOCAL URL is %@", initialUrl);
    [self loadUrl];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self addGestureRecognizer];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGSize rootViewSize = [SUYUtils rootViewSizeOf:self.view];
    self.view.superview.bounds = CGRectMake(0, 0, rootViewSize.width*.9, rootViewSize.height*.99);
    self.view.superview.alpha = 1.0;
}

#pragma mark Private

- (WKWebViewConfiguration*)createConfig {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    config.userContentController = wkUController;
    return config;
}



- (void)loadUrl {
    NSURL *url = [NSURL fileURLWithPath: initialUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

- (void)addGestureRecognizer
{
    if(gestureRecognizer != nil){ return; }
    gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [gestureRecognizer setNumberOfTapsRequired:1];
    gestureRecognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:gestureRecognizer];
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

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark Releasing

- (IBAction)close:(UIButton*)sender
{
    [self.view.window removeGestureRecognizer:gestureRecognizer];
    [self dismissViewControllerAnimated:YES completion:nil];
    gestureRecognizer = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self close: nil];
}

@end
