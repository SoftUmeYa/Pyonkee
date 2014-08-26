//
//  SUYWebViewController.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/01.
//
//

#import <UIKit/UIKit.h>

@interface SUYWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) UITapGestureRecognizer *gestureRecognizer;
@property (nonatomic, retain) NSString*        initialUrl;

- (IBAction)close:(UIButton *)sender;

@end
