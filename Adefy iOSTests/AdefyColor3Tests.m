#import <XCTest/XCTest.h>
#import "AdefyColor3.h"

@interface AdefyColor3Tests : XCTestCase
@end

@implementation AdefyColor3Tests {

@protected
  AdefyColor3 *mColor;
}

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  mColor = nil;
  [super tearDown];
}

- (void) testInitWithComponents {

  mColor = [[AdefyColor3 alloc] init:140 withG:120 withB:130];
  XCTAssertEqual(140, [mColor getR]);
  XCTAssertEqual(120, [mColor getG]);
  XCTAssertEqual(130, [mColor getB]);
}

- (void) testInitWithFloatComponents {

  // Rounds up
  mColor = [[AdefyColor3 alloc] init:0.501f withGF:0.501f withBF:0.501f];
  XCTAssertEqual(128, [mColor getR]);
  XCTAssertEqual(128, [mColor getG]);
  XCTAssertEqual(128, [mColor getB]);

  // Rounds down
  mColor = [[AdefyColor3 alloc] init:0.499f withGF:0.499f withBF:0.499f];
  XCTAssertEqual(127, [mColor getR]);
  XCTAssertEqual(127, [mColor getG]);
  XCTAssertEqual(127, [mColor getB]);
}

- (void) testSettersAndGetters {

  mColor = [[AdefyColor3 alloc] init:140 withG:120 withB:130];

  [mColor setR:1];
  [mColor setG:2];
  [mColor setB:3];
  [mColor setA:4];

  XCTAssertEqual(1, [mColor getR]);
  XCTAssertEqual(2, [mColor getG]);
  XCTAssertEqual(3, [mColor getB]);
  XCTAssertEqual(4, [mColor getA]);
}

- (void) testFloatArrayConversion {

  // Test with integer init
  mColor = [[AdefyColor3 alloc] init:140 withG:120 withB:130];

  float *array = [mColor toFloatArray];
  XCTAssertEqual(array[0], 140 / 255.0f);
  XCTAssertEqual(array[1], 120 / 255.0f);
  XCTAssertEqual(array[2], 130 / 255.0f);
  XCTAssertEqual(array[3], 1.0f); // Defaults to 255 alpha
  free(array);

  // Test with float init (should not be rounded!
  mColor = [[AdefyColor3 alloc] init:0.235f withGF:0.463f withBF:0.325f];

  array = [mColor toFloatArray];
  XCTAssertEqual(array[0], 0.235f);
  XCTAssertEqual(array[1], 0.463f);
  XCTAssertEqual(array[2], 0.325f);
  XCTAssertEqual(array[3], 1.0f);
  free(array);
}

- (void) testFloatArrayCopy {

  float *array = malloc(sizeof(float) * 4);

  mColor = [[AdefyColor3 alloc] init:0.235f withGF:0.463f withBF:0.325f];
  [mColor copyToFloatArray:array];

  XCTAssertEqual(array[0], 0.235f);
  XCTAssertEqual(array[1], 0.463f);
  XCTAssertEqual(array[2], 0.325f);
  XCTAssertEqual(array[3], 1.0f);
  free(array);
}

@end
