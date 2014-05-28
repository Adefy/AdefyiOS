#import "AdefyDemoMenuController.h"
#import "AdefyViewStyles.h"
#import "AdefyDownloader.h"
#import "AdefyViewController.h"

#define WATCH_DEMO_NAME @"ios_showcase_watch"
#define SKITTLE_DEMO_NAME @"ios_showcase_skittle"
#define TEST_DEMO_NAME @"ios_showcase_test"

void styleDemoImageButton(UIButton *button, float offset) {
  CGSize imageSize = button.imageView.frame.size;
  button.imageEdgeInsets = UIEdgeInsetsMake(0.0, offset - imageSize.width / 2.0f, 0.0, 0.0);
  styleButton(button);
}

@implementation AdefyDemoMenuController {

@protected
  BOOL mWatchDemoReady;
  BOOL mSkittleDemoReady;
  BOOL mTestDemoReady;

  AdefyDownloader *mAdDownloader;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  //
  // Style UI
  //

  styleDemoImageButton(self.WatchDemoButton, 40.0f);
  styleDemoImageButton(self.SkittleDemoButton, 40.0f);
  styleDemoImageButton(self.TestDemoButton, 23.0f);

  self.DemoLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:20];
  self.LogoLabel.font = [UIFont fontWithName:@"OleoScript-Regular" size:64];

  // Demo buttons
  [self.WatchDemoButton addTarget:self action:@selector(showWatchDemo) forControlEvents:UIControlEventTouchUpInside];
  [self.SkittleDemoButton addTarget:self action:@selector(showSkittleDemo) forControlEvents:UIControlEventTouchUpInside];
  [self.TestDemoButton addTarget:self action:@selector(showTestDemo) forControlEvents:UIControlEventTouchUpInside];

  //
  // Prepare ad demos
  //
  mAdDownloader = [[AdefyDownloader alloc] init:@"IOS_SHOWCASE"];

  // Check which demos we already have
  mWatchDemoReady = [mAdDownloader adDownloaded:WATCH_DEMO_NAME];
  mSkittleDemoReady = [mAdDownloader adDownloaded:SKITTLE_DEMO_NAME];
  mTestDemoReady = [mAdDownloader adDownloaded:TEST_DEMO_NAME];

  // Download those we are missing
  if(!mWatchDemoReady) {
    [mAdDownloader fetchAd:WATCH_DEMO_NAME withDurationMS:1000 withTemplate:@"watch_template" withCB:^{
        mWatchDemoReady = YES;
        self.WatchDemoButton.enabled = YES;
        [self updateDownloadingMessage];
    }];
  } else {
    self.WatchDemoButton.enabled = YES;
  }

  if(!mSkittleDemoReady) {
    [mAdDownloader fetchAd:SKITTLE_DEMO_NAME withDurationMS:1000 withTemplate:@"skittle_template" withCB:^{
        mSkittleDemoReady = YES;
        self.SkittleDemoButton.enabled = YES;
        [self updateDownloadingMessage];
    }];
  } else {
    self.SkittleDemoButton.enabled = YES;
  }

  if(!mTestDemoReady) {
    [mAdDownloader fetchAd:TEST_DEMO_NAME withDurationMS:1000 withTemplate:@"test" withCB:^{
        mTestDemoReady = YES;
        self.TestDemoButton.enabled = YES;
        [self updateDownloadingMessage];
    }];
  } else {
    self.TestDemoButton.enabled = YES;
  }

  // Refresh message in case all demos are already present
  [self updateDownloadingMessage];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void) goBack {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void) showWatchDemo {
  if(!mWatchDemoReady) { return; }
}

- (void) showSkittleDemo {
  if(!mSkittleDemoReady) { return; }
}

- (void) showTestDemo {
  if(!mTestDemoReady) { return; }
}

- (void) updateDownloadingMessage {
  if(mWatchDemoReady && mSkittleDemoReady && mTestDemoReady) {
    self.DemoLabel.text = @"Demos";
  }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

  NSLog(@"prepareForSegue: %@", segue.identifier);

  // Show nav bar
  [self.navigationController setNavigationBarHidden:NO animated:YES];

  NSString *adName;
  NSString *adTemplate;
  NSNumber *adDuration = [NSNumber numberWithInt:5000];

  if ([segue.identifier isEqualToString:@"watch"]) {
    adName = WATCH_DEMO_NAME;
    adTemplate = @"watch_template";
  } else if ([segue.identifier isEqualToString:@"skittle"]) {
    adName = SKITTLE_DEMO_NAME;
    adTemplate = @"skittle_template";
  } else if ([segue.identifier isEqualToString:@"test"]) {
    adName = TEST_DEMO_NAME;
    adTemplate = @"test";
  } else {
    NSLog(@"Unknown target ad %@! Adefy ad view will use defaults!", segue.identifier);
  }

  [segue.destinationViewController launchForAd:adName
                                withDurationMS:adDuration
                                  withTemplate:adTemplate];

}

- (void)viewWillAppear:(BOOL)animated {
  [self.navigationController setNavigationBarHidden:NO animated:animated];
  [super viewWillAppear:animated];
}

@end
