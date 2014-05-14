//
//  AddImagesViewControllerTests.m
//  AddContacts
//
//  Created by Jason Bandy on 3/11/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "OCMock.h"
#import "AddImagesViewController.h"
#import "ALAssetsLibraryMock.h"

@interface AddImagesViewControllerTests : XCTestCase

@end

@interface AddImagesViewController(AddAssestsVC_UnitTests)

@property (strong, nonatomic)UIImageView *imageViewToAdd;
@property (strong, nonatomic)UITextView *imageInfoView;
@property (strong, nonatomic)UITextField *quantityTextField;
@property (strong, nonatomic)UIProgressView *progressBarView;
@property (strong, nonatomic)ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic)NSUserDefaults *defaults;
@property (nonatomic) int numImages;


-(UIImage *)imageToAdd;
-(void)addImagesToAssets;
- (BOOL)isNumeric:(NSString *)inputString;
@end
void MethodClassSwizzle(Class c, SEL orig, SEL new);

void MethodClassSwizzle(Class c, SEL orig, SEL new) {
    Method origMethod = class_getClassMethod(c, orig);
    Method newMethod = class_getClassMethod(c, new);
    method_exchangeImplementations(origMethod, newMethod);
}

static ALAuthorizationStatus staticMockAuthorizationStatus;

@implementation AddImagesViewControllerTests{
    AddImagesViewController *assetsViewController;
    UITextField *testField;
}

+ (ALAuthorizationStatus)mockAuthorizationStatus {
    return staticMockAuthorizationStatus;
}


- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before te invocation of each test method in the class.
    assetsViewController = [[AddImagesViewController alloc]init];
    
    ALAssetsLibraryMock * mockLib = [[ALAssetsLibraryMock alloc]init];
    assetsViewController.assetsLibrary =  mockLib;
    
    ALAssetsGroupMock *mockGroup = [[ALAssetsGroupMock alloc]init];
    mockLib.group = mockGroup;
    
    MethodClassSwizzle([ALAssetsLibrary class], @selector(authorizationStatus), @selector(mockAuthorizationStatus));
    staticMockAuthorizationStatus = ALAuthorizationStatusAuthorized; 
    
    testField = [[UITextField alloc]init];
}

- (void)tearDown
{
    assetsViewController = nil;
    // Put teardown code  here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//-(void)testDidImageToAddReturnValue {
//    XCTAssertNotNil(assetsViewController.imageToAdd, @"Test Failed: Imaged returned nil.");
//    XCTAssertEqual([assetsViewController.imageToAdd class], [UIImage class], @"Imaged returned non UIImage class type.");
//
//}

-(void)testTextFieldShouldReturn_NotNumber_ReturnsNO {
    testField.text = @"foo";
    XCTAssertFalse([assetsViewController textFieldShouldReturn:testField], @"TextField returned YES for non-numeric value.");
}

-(void)testTextFieldShouldReturn_IsNumber_ReturnsYES {
    testField.text = @"123";
    XCTAssertTrue([assetsViewController textFieldShouldReturn:testField], @"TextField returned No for numeric value.");
}

-(void)testTextFieldShouldReturn_NegativeNumber_ReturnsNO{
    testField.text = @"-1";
    XCTAssertFalse([assetsViewController textFieldShouldReturn:testField], @"TextField returned YES for a negative number.");
}

-(void)testTextFieldShouldReturn_PositiveNumber_ReturnsYES{
    testField.text = @"1";
    XCTAssertTrue([assetsViewController textFieldShouldReturn:testField], @"TextField returned NO for a positive number.");
}

-(void)testTextFieldShouldReturn_GivenNumber_MatchesMemberVariableNumber{
    int localNum = 10;
    testField.text = @"10";
    [assetsViewController textFieldShouldReturn:testField];
    XCTAssertEqual(localNum, assetsViewController.numImages, @"TextField should return did not set number of images member variable.");
}

//- Images added to album = "Test Photos!"
-(void)testAddImagesToAssets{
    // Given that 10 images are added to album
    __block int imagesFromAlbumCount = 0;
    testField.text = @"10";// should add 10 images to album
    [assetsViewController textFieldShouldReturn:testField];
    [assetsViewController addImagesToAssets];
    
    // retrieve all photos in the album "Test Photos!"
    [assetsViewController.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                               usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                       //enumerate photos
                                       [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                           if (result) {
                                               imagesFromAlbumCount++;
                                           }
                                       }];
                               } failureBlock:^(NSError *error) {
                                   
                               }];
    XCTAssertEqual(imagesFromAlbumCount,10, @"Images not Added to \"Test Photos\" album");
}

@end
