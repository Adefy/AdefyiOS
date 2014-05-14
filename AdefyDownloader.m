#import "AdefyDownloader.h"
#import "SSZipArchive.h"
#import <AdSupport/ASIdentifierManager.h>

NSString *DEFAULT_ADEFY_SERVER = @"https://app.adefy.com/api/v1/serve";
NSString *DEFAULT_AD_TYPE = nil;

NSFileManager *FILE_MANAGER;
NSMutableString *CACHE_DIR;

@implementation AdefyDownloader {

@protected
  NSString *apiKey;
  NSString *adType;
  NSString *serverURL;
}

+ (void)initialize {

  FILE_MANAGER = [[NSFileManager alloc] init];
  CACHE_DIR = [AdefyDownloader getCacheDir];

  if(![AdefyDownloader cacheDirectoryExists]) {
    NSLog(@"Cache directory doesn't exist, creating (%@)...", CACHE_DIR);

    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:CACHE_DIR
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];

    if(!success) {
      NSLog(@"Error creating cache dir: %@ %@", error, [error userInfo]);
    } else {
      NSLog(@"...done");
    }
  }
}

/**
* Get the full path to the ad cache directory
*
* @return cache_dir_path
*/
+ (NSMutableString *)getCacheDir {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

  return [NSMutableString stringWithFormat:@"%@/adefy/ads/", documentsPath];
}

/**
* Check if the ad cache directory exists. This does NOT create it!
*
* @return exists
*/
+ (BOOL)cacheDirectoryExists {

  BOOL isDir;
  BOOL exists = [FILE_MANAGER fileExistsAtPath:CACHE_DIR
                                   isDirectory:&isDir];

  return isDir && exists;
}

/**
* Initialises us with a custom server URL. Not recommended for useage.
*
* @param apikey Publisher API Key
* @param server_url Ad server URL, including protocol and serve API suffix
* @param ad_type Name of desired ad type, case sensitive
* @return self
*/
- (AdefyDownloader *)init:(NSString *)_apiKey
             withAdServer:(NSString *)_url
                   ofType:(NSString *)_adType {

  self = [super init];

  apiKey = _apiKey;
  serverURL = _url;
  adType = _adType;

  return self;
}

/**
* Initialise with an API key and a custom ad type; use this to
* request specific ads from the server for display by name; should
* only be used by Adefy demo apps, as normal requests are handled
* by our platform.
*
* If requesting using a live API key and a non-standard name, any
* generated impression or click will not count towards your earnings!
*
* @param apikey Publisher API key
* @param ad_type Name of desired ad type, case sensitive
* @return self
*/
- (AdefyDownloader *)init:(NSString *)_apiKey
                   ofType:(NSString *)_adType {
  return [self init:_apiKey
       withAdServer:DEFAULT_ADEFY_SERVER
             ofType:_adType];
}

/**
* Initialise with an API key, using the default server URL and ad type.
* This initialiser should be used for the majority of applications!
*
* @param apikey Publisher API key
* @return self
*/
- (AdefyDownloader *)init:(NSString *)_apiKey {
  return [self init:_apiKey
       withAdServer:DEFAULT_ADEFY_SERVER
             ofType:DEFAULT_AD_TYPE];
}

/**
* Builds and returns a dictionary containing information about the
* current client, suitable for building a server query string and
* requesting an ad. The dictionary contains keys for "UUID", "Width",
* and "Height".
*
* @return user_information Dictionary containing client information
*/
- (NSMutableDictionary *)getUserInformation {
  NSMutableDictionary *uInfo = [[NSMutableDictionary alloc] init];

  ASIdentifierManager* advertisingIdentManager = [ASIdentifierManager sharedManager];
  CGRect screenRect = [[UIScreen mainScreen] bounds];

  NSNumber *screenWidth = [NSNumber numberWithInt:(int)screenRect.size.width];
  NSNumber *screenHeight = [NSNumber numberWithInt:(int) screenRect.size.height];
  NSString *uuid = [advertisingIdentManager.advertisingIdentifier UUIDString];

  [uInfo setObject:uuid forKey:@"UUID"];
  [uInfo setObject:screenWidth forKey:@"Width"];
  [uInfo setObject:screenHeight forKey:@"Height"];
  // Note that we don't pass the username, as Apple doesn't like that

  return uInfo;
}

/**
* Builds and returns a suitable query string for our server (GET params)
* This string contains the information needed to identify us and let
* the server peform any necessary targeting. It also contains our APIkey,
* which authorizes us for the request
*
* @return queryString
*/
- (NSString *)getQueryString:(NSString *)template {
  NSMutableString *query = [NSMutableString stringWithString:serverURL];
  NSMutableDictionary *userInformation = [self getUserInformation];

  NSNumber * width = [userInformation objectForKey:@"Width"];
  NSNumber * height = [userInformation objectForKey:@"Height"];
  NSString *uuid = [userInformation objectForKey:@"UUID"];

  [query appendFormat:@"?apikey=%@&type=organic&width=%i&height=%i&uuid=%@",
          apiKey, [width intValue], [height intValue], uuid];

  if(template) {
    [query appendFormat:@"&template=%@", template];
  }

  return query;
}

/**
* Downloads and prepares an ad for execution under the provided name. Requests
* an ad with a length as close as possible to the provided duration, but there
* is no gaurantee the served ad is of, or close to the duration!
*
* This method is asynchronous!
*
* @param name Ad name for future reference
* @param duration Ad length in milliseconds
*/
- (void)fetchAd:(NSString *)name
 withDurationMS:(int)duration
   withTemplate:(NSString *)template {

  // Get queue handles
  dispatch_queue_t backgroundQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_queue_t mainQ = dispatch_get_main_queue();

  // Start primary download
  dispatch_async(backgroundQ, ^{

    @autoreleasepool {
      NSLog(@"Starting Adefy GLAd download...");

      NSURL *url = [NSURL URLWithString:[self getQueryString:template]];
      NSError *downloadError;

      NSData *data = [NSData dataWithContentsOfURL:url
                                           options:NSDataReadingUncached
                                             error:&downloadError];

      if(downloadError) {
        NSLog(@"Error downloading Adefy GLAd: %@", [downloadError localizedDescription]);
        return;
      }

      NSString *downloadPath = [CACHE_DIR stringByAppendingPathComponent:name];
      NSString *finalFilename = [NSString stringWithFormat:@"%@.ttx", downloadPath];
      NSString *extractPath = [NSString stringWithFormat:@"%@_extracted/", downloadPath];


      // Perform download (blocks!)
      [data writeToFile:finalFilename atomically:YES];

      NSLog(@"Downloaded Adefy GLAd '%@' (%i bytes)", name, [data length]);

      // Upzip
      [SSZipArchive unzipFileAtPath:finalFilename
                      toDestination:extractPath];

      NSLog(@"Extracted Adefy GLAd '%@'", name);

      // [self loadGLAdFromDirectory:extractPath];
      // dispatch_async(mainQ, ^{});
    }
  });
}

- (NSString *)getPathForGLAd:(NSString *)name {
  return [NSString stringWithFormat:@"%@%@_extracted/", CACHE_DIR, name];
}

@end