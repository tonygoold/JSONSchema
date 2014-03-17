//
//  JSONSchemaTests.m
//  Wattpad
//
//  Created by R. Tony Goold on 2014-01-16.
//  Copyright (c) 2014 N/A. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JSONSchema.h"

@interface JSONSchemaTests : XCTestCase

@end

@implementation JSONSchemaTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)assertError:(NSError *)error code:(NSInteger)code
{
    XCTAssertNotNil(error, @"Error object was not set");
    if (!error)
        return;
    XCTAssertEqualObjects(error.domain, JSONSchemaErrorDomain, @"Error object does not have correct domain");
    XCTAssertEqual(error.code, code, @"Wrong type failure gave incorrect error code");
}

- (void)testString
{
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode stringNode]];
    XCTAssertTrue([schema checkObject:@"a string" error:nil], @"String schema did not match string");
}

- (void)testNumber
{
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode numberNode]];
    XCTAssertTrue([schema checkObject:@123 error:nil], @"Number schema did not match number");
}

- (void)testBoolean
{
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode booleanNode]];
    XCTAssertTrue([schema checkObject:@NO error:nil], @"Boolean schema did not match boolean");
}

- (void)testAnyLiteral
{
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode anyLiteralNode]];
    XCTAssertTrue([schema checkObject:@"a string" error:nil], @"Any literal schema did not match string");
    XCTAssertTrue([schema checkObject:@123 error:nil], @"Any literal schema did not match number");
    XCTAssertTrue([schema checkObject:@NO error:nil], @"Any literal schema did not match boolean");
    XCTAssertFalse([schema checkObject:@[] error:nil], @"Any literal schema matched an array");
    XCTAssertFalse([schema checkObject:@{} error:nil], @"Any literal schema matched a dictionary");
    XCTAssertFalse([schema checkObject:nil error:nil], @"Any literal schema matched nil");
}

- (void)testAny
{
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode anyNode]];
    XCTAssertTrue([schema checkObject:@"a string" error:nil], @"Any schema did not match string");
    XCTAssertTrue([schema checkObject:@123 error:nil], @"Any schema did not match number");
    XCTAssertTrue([schema checkObject:@NO error:nil], @"Any schema did not match boolean");
    XCTAssertTrue([schema checkObject:@[] error:nil], @"Any schema matched an array");
    XCTAssertTrue([schema checkObject:@{} error:nil], @"Any schema matched a dictionary");
    XCTAssertFalse([schema checkObject:nil error:nil], @"Any schema matched nil");
}

- (void)testOptionalNodeCreators
{
    JSONSchemaNode *string = [JSONSchemaNode optionalStringNode];
    JSONSchemaNode *number = [JSONSchemaNode optionalNumberNode];
    JSONSchemaNode *boolean = [JSONSchemaNode optionalBooleanNode];
    JSONSchemaNode *anyLiteral = [JSONSchemaNode anyOptionalLiteralNode];
    JSONSchemaNode *any = [JSONSchemaNode anyOptionalNode];
    XCTAssertTrue(string.options & JSONSchemaOptional, @"optionalStringNode is not optional");
    XCTAssertTrue(number.options & JSONSchemaOptional, @"optionalNumberNode is not optional");
    XCTAssertTrue(boolean.options & JSONSchemaOptional, @"optionalBooleanNode is not optional");
    XCTAssertTrue(anyLiteral.options & JSONSchemaOptional, @"anyOptionalLiteralNode is not optional");
    XCTAssertTrue(any.options & JSONSchemaOptional, @"anyOptionalNode is not optional");
}

- (void)testMissingRoot
{
    JSONSchema *schema = [[JSONSchema alloc] init];
    NSError *error = nil;
    XCTAssertFalse([schema checkObject:@"anything" error:&error], @"Empty schema should not match anything");
    [self assertError:error code:JSONSchemaErrorMissingRoot];
}

- (void)testWrongTypeFailure
{
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode stringNode]];
    NSError *error = nil;
    XCTAssertFalse([schema checkObject:@123 error:&error], @"String schema should not match a non-string object");
    [self assertError:error code:JSONSchemaErrorWrongType];
}

- (void)testNilObjectFailure
{
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode stringNode]];
    NSError *error = nil;
    XCTAssertFalse([schema checkObject:nil error:&error], @"String schema should not match nil");
    [self assertError:error code:JSONSchemaErrorWrongType];
}

- (void)testDictionary
{
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeDictionary
                                                        options:0
                                                          child:@{ @"key": [JSONSchemaNode anyNode] }];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSDictionary *dict = @{ @"key": @0 };
    XCTAssertTrue([schema checkObject:dict error:nil], @"Dictionary schema did not match dictionary");
}

- (void)testDictionaryWithExtraKeys
{
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeDictionary
                                                        options:0
                                                          child:@{ @"key": [JSONSchemaNode anyNode] }];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSDictionary *dict = @{ @"key": @0, @"another": @1 };
    XCTAssertTrue([schema checkObject:dict error:nil], @"Dictionary schema did not match dictionary with extra keys");
}

- (void)testDictionaryWrongChildType
{
    XCTAssertThrowsSpecificNamed([[JSONSchemaNode alloc] initWithType:JSONSchemaNodeDictionary
                                                              options:0
                                                                child:[JSONSchemaNode anyNode]],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Should not be able to create dictionary schema with wrong child type");
}

- (void)testDictionaryMissingKey
{
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeDictionary
                                                        options:0
                                                          child:@{ @"key": [JSONSchemaNode stringNode] }];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSDictionary *dict = @{};
    NSError *error = nil;
    XCTAssertFalse([schema checkObject:dict error:&error], @"Dictionary schema did not detect missing key");
    [self assertError:error code:JSONSchemaErrorMissingKey];
}

- (void)testDictionaryStrictFailure
{
    
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeDictionary
                                                        options:JSONSchemaStrictDictionaries
                                                          child:@{ @"key": [JSONSchemaNode anyNode] }];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSDictionary *dict = @{ @"key": @0, @"another": @1 };
    NSError *error = nil;
    XCTAssertFalse([schema checkObject:dict error:&error], @"Strict dictionary schema should not match dictionary with unexpected key");
    [self assertError:error code:JSONSchemaErrorUnexpectedEntry];
}

- (void)testArray
{
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeArray
                                                        options:0
                                                          child:[JSONSchemaNode anyNode]];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSArray *array = @[ @0 ];
    XCTAssertTrue([schema checkObject:array error:nil], @"Array schema did not match array");
}

- (void)testEmptyArray
{
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeArray
                                                        options:0
                                                          child:[JSONSchemaNode anyNode]];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSArray *array = @[];
    XCTAssertTrue([schema checkObject:array error:nil], @"Array schema did not match empty array");
}

- (void)testAnyLiteralArray
{
    JSONSchema *schema = [JSONSchema schemaForObject:@[ [JSONSchemaNode anyLiteralNode ] ] error:nil];
    NSArray *array = @[ @"string", @1234, @YES ];
    XCTAssertTrue([schema checkObject:array error:nil], @"Array schema did not match array of any literal");
}

- (void)testArrayWrongChildType
{
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeArray
                                                        options:0
                                                          child:@{ @"key": [JSONSchemaNode anyNode] }];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSArray *array = @[ @0 ];
    NSError *error = nil;
    XCTAssertFalse([schema checkObject:array error:&error], @"Array schema without a child should not match anything");
    [self assertError:error code:JSONSchemaErrorInvalidSchemaNode];
}

- (void)testArrayNonEmptyFailure
{
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeArray
                                                        options:JSONSchemaNonEmptyArray
                                                          child:[JSONSchemaNode anyNode]];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSArray *array = @[];
    NSError *error = nil;
    XCTAssertFalse([schema checkObject:array error:&error], @"Non-empty array schema should not match empty array");
    [self assertError:error code:JSONSchemaErrorEmptyArray];
}

- (void)testNodeForObjectString
{
    NSString *string = @"a string";
    JSONSchemaNode *node = [JSONSchema nodeForObject:string error:nil];
    XCTAssertNotNil(node, @"Failed to turn a string into a schema node");
    XCTAssertEqual(node.type, JSONSchemaNodeString, @"Turned a string into wrong type of schema node");
}

- (void)testNodeForObjectNumber
{
    NSNumber *number = @123;
    JSONSchemaNode *node = [JSONSchema nodeForObject:number error:nil];
    XCTAssertNotNil(node, @"Failed to turn a number into a schema node");
    XCTAssertEqual(node.type, JSONSchemaNodeNumber, @"Turned a number into wrong type of schema node");
}

- (void)testNodeForObjectBoolean
{
    NSNumber *boolean = @YES;
    JSONSchemaNode *node = [JSONSchema nodeForObject:boolean error:nil];
    XCTAssertNotNil(node, @"Failed to turn a boolean into a schema node");
    // Can't distinguish between number and boolean, so it turns booleans into numbers
    XCTAssertEqual(node.type, JSONSchemaNodeNumber, @"Turned a boolean into wrong type of schema node");
}

- (void)testNodeForObjectArray
{
    // Array needs to contain a single item
    NSArray *array = @[ @"a string" ];
    JSONSchemaNode *node = [JSONSchema nodeForObject:array error:nil];
    XCTAssertNotNil(node, @"Failed to turn an array into a schema node");
    XCTAssertEqual(node.type, JSONSchemaNodeArray, @"Turned an array into wrong type of schema node");
}

- (void)testNodeForObjectDictionary
{
    NSDictionary *dictionary = @{};
    JSONSchemaNode *node = [JSONSchema nodeForObject:dictionary error:nil];
    XCTAssertNotNil(node, @"Failed to turn a dictionary into a schema node");
    XCTAssertEqual(node.type, JSONSchemaNodeDictionary, @"Turned a dictionary into wrong type of schema node");
}

- (void)testNodeForObjectSchemaNode
{
    JSONSchemaNode *source = [JSONSchemaNode stringNode];
    JSONSchemaNode *dest = [JSONSchema nodeForObject:source error:nil];
    XCTAssertEqual(source, dest, @"nodeForObject did not return schema node passed as object");
}

- (void)testNodeForObjectArrayWithSchemaNode
{
    JSONSchemaNode *node = [JSONSchemaNode stringNode];
    JSONSchemaNode *arrayNode = [JSONSchema nodeForObject:@[ node ] error:nil];
    XCTAssertEqual(node, arrayNode.child, @"nodeForObject did not preserve schema node passed as array child");
}

- (void)testNodeForObjectDictionaryWithSchemaNode
{
    JSONSchemaNode *node = [JSONSchemaNode stringNode];
    JSONSchemaNode *dictionaryNode = [JSONSchema nodeForObject:@{ @"node": node } error:nil];
    XCTAssertEqual(node, dictionaryNode.child[@"node"], @"nodeForObject did not preserve schema node passed as dictionary child value");
}

// Test creating a schema from a plist prototype
- (void)testPlistPrototype
{
    id object = @{ @"stories": @[ @{ @"id": @1, @"title": @"asdf", @"user": @{ @"name": @"username", @"id": @1234 } } ] };
    NSError *error = nil;
    JSONSchemaNode* root = [JSONSchema nodeForObject:object error:&error];
    XCTAssertNotNil(root, @"Failed to turn plist prototype into a schema: %@", error);
    JSONSchemaNode *stories = root.child[@"stories"];
    XCTAssertNotNil(stories, @"Failed to identify stories dictionary key");
    JSONSchemaNode *story = stories.child;
    XCTAssertNotNil(story, @"Failed to transform array object into specification");
    if (story.type != JSONSchemaNodeDictionary)
    {
        XCTFail(@"Failed to transform story object into a dictionary specification");
        return;
    }
    NSDictionary *storyDict = story.child;
    JSONSchemaNode *storyIdNode = storyDict[@"id"];
    JSONSchemaNode *storyTitleNode = storyDict[@"title"];
    XCTAssertEqual(storyIdNode.type, JSONSchemaNodeNumber, @"story id is not a number node");
    XCTAssertEqual(storyTitleNode.type, JSONSchemaNodeString, @"story title is not a string node");
    JSONSchemaNode *user = storyDict[@"user"];
    XCTAssertEqual(user.type, JSONSchemaNodeDictionary, @"user is not a dictionary node");
    NSDictionary *userDict = user.child;
    JSONSchemaNode *userIdNode = userDict[@"id"];
    JSONSchemaNode *userNameNode = userDict[@"name"];
    XCTAssertEqual(userIdNode.type, JSONSchemaNodeNumber, @"user id is not a number node");
    XCTAssertEqual(userNameNode.type, JSONSchemaNodeString, @"user name is not a string node");

    // Finally, test that the example validates against its own schema
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:root];
    XCTAssertTrue([schema checkObject:object error:nil], @"Failed to validate plist prototype against its own generated schema");
}

// Check that plist objects and schema nodes can be mixed
- (void)testMixedExample
{
    JSONSchemaNode *optionalStringNode = [JSONSchemaNode optionalStringNode];
    JSONSchemaNode *arrayNode = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeArray
                                                             options:0
                                                               child:[JSONSchemaNode numberNode]];
    id object = @{ @"optionalStringNode": optionalStringNode,
                   @"array": @[ [JSONSchemaNode booleanNode] ],
                   @"arrayNode": arrayNode };
    JSONSchema *schema = [JSONSchema schemaForObject:object error:nil];
    XCTAssertNotNil(schema, @"Failed to create schema from mixed plist and schema node prototype");
    id sample1 = @{ @"optionalStringNode": [NSNull null],
                    @"array": @[ @NO, @YES ],
                    @"arrayNode": @[ @1, @2 ] };
    XCTAssertTrue([schema checkObject:sample1 error:nil], @"Failed to match schema from mixed plist and schema node prototype");
}

- (void)testTransformString
{
    NSString *source = @"a string";
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode stringNode]];
    NSString *dest = [schema transformObject:source error:nil];
    XCTAssertEqual(source, dest, @"Transforming string to itself did not return same object");
}

- (void)testTransformNumber
{
    id source = @1234;
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode numberNode]];
    id dest = [schema transformObject:source error:nil];
    XCTAssertEqual(source, dest, @"Transforming number to itself did not return same object");
}

- (void)testTransformBoolean
{
    id source = @YES;
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:[JSONSchemaNode booleanNode]];
    id dest = [schema transformObject:source error:nil];
    XCTAssertEqual(source, dest, @"Transforming boolean to itself did not return same object");
}

- (void)testTransformOptionalWithDefault
{
    NSString *expected = @"a default";
    JSONSchemaNode *node = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeString
                                                        options:JSONSchemaOptional default:expected];
    JSONSchema *schema = [[JSONSchema alloc] initWithRootNode:node];
    NSString *output = [schema transformObject:nil error:nil];
    XCTAssertEqualObjects(output, expected, @"Failed to transform optional node to default value");
}

- (void)testTransformArrayStrict
{
    NSArray *input = @[ @"str1", @"str2", @1234, @"str3" ];
    JSONSchema *schema = [JSONSchema schemaForObject:@[ @"" ] error:nil];
    NSArray *output = [schema transformObject:input error:nil];
    XCTAssertNil(output, @"Should not have transformed an array with invalid child");
}

- (void)testTransformArrayLenient
{
    NSArray *input = @[ @"str1", @"str2", @1234, @"str3" ];
    NSArray *expected = @[ @"str1", @"str2", @"str3" ];
    JSONSchemaNode *lenientString = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeString
                                                                 options:JSONSchemaUseDefaultOnError];
    JSONSchema *schema = [JSONSchema schemaForObject:@[ lenientString ] error:nil];
    NSArray *output = [schema transformObject:input error:nil];
    XCTAssertEqualObjects(output, expected, @"Did not transform array with an error-permitting child");
}

- (void)testTransformArrayOptionalNotInvalid
{
    NSArray *input = @[ @"str1", @"str2", @1234, @"str3" ];
    JSONSchema *schema = [JSONSchema schemaForObject:@[ [JSONSchemaNode optionalStringNode] ] error:nil];
    NSArray *output = [schema transformObject:input error:nil];
    XCTAssertNil(output, @"Should not have transformed an array with invalid child against optional child node");
}

- (void)testTransformDictionaryStrict
{
    NSDictionary *input = @{ @"str": @1234 };
    JSONSchema *schema = [JSONSchema schemaForObject:@{ @"str": @"" } error:nil];
    NSDictionary *output = [schema transformObject:input error:nil];
    XCTAssertNil(output, @"Should not have transformed a dictionary with an invalid child");
}

- (void)testTransformDictionaryOptional
{
    NSDictionary *input = @{};
    NSDictionary *expected = @{};
    JSONSchema *schema = [JSONSchema schemaForObject:@{ @"str": [JSONSchemaNode optionalStringNode] } error:nil];
    NSDictionary *output = [schema transformObject:input error:nil];
    XCTAssertEqualObjects(output, expected, @"Failed to transform a dictionary with an optional child");
}

- (void)testTransformDictionaryOptionalNotInvalid
{
    NSDictionary *input = @{ @"str": @1234 };
    JSONSchema *schema = [JSONSchema schemaForObject:@{ @"str": [JSONSchemaNode optionalStringNode] } error:nil];
    NSDictionary *output = [schema transformObject:input error:nil];
    XCTAssertNil(output, @"Should not have transformed a dictionary with an invalid but optional child");
}

- (void)testTransformDictionaryAllowError
{
    NSDictionary *input = @{ @"str": @1234 };
    NSDictionary *expected = @{};
    JSONSchemaNode *lenientString = [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeString
                                                                 options:JSONSchemaUseDefaultOnError];
    JSONSchema *schema = [JSONSchema schemaForObject:@{ @"str": lenientString } error:nil];
    NSDictionary *output = [schema transformObject:input error:nil];
    XCTAssertEqualObjects(output, expected, @"Failed to transform a dictionary with an error-permitting child");
}

@end
