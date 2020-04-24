//
//  SUYWebViewController.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/01.
//
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface SUYWebViewController : UIViewController <WKNavigationDelegate>

@property (nonatomic) WKWebView *webView;
@property (nonatomic) UITapGestureRecognizer *gestureRecognizer;
@property (nonatomic) NSString*        initialUrl;

- (IBAction)close:(UIButton *)sender;

@end
