//
//  JSONSchema.h
//  Wattpad
//
//  Created by R. Tony Goold on 2014-01-14.
//  Copyright (c) 2014 N/A. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    /**
     * Reject dictionaries that contain keys not specified in the
     * schema. By default, dictionary key-values that are not
     * included in the schema have no effect on validation.
     */
    JSONSchemaStrictDictionaries    = 1 << 0,
    /**
     * Reject empty arrays. By default, arrays that are empty will
     * always pass validation, since the validation condition is
     * trivially true for all items.
     */
    JSONSchemaNonEmptyArray         = 1 << 1,
    /**
     * The node is optional and can be omitted. During transformation,
     * if the node has a default value specified, that value will be
     * used if not found (dictionary values) or NSNull is encountered.
     * The default behaviour is to fail validation and transformation
     * if a specified node is not found.
     */
    JSONSchemaOptional              = 1 << 2,
    /**
     * During transformation, if a node fails validation, it will be
     * replaced by the node's default value (if specified), otherwise
     * it will be omitted (array and dictionary values). If the root
     * of the schema fails validation, transformation will return nil.
     * This option has no effect on schema validation. The default
     * behaviour is to stop transformation on the first validation
     * failure.
     */
    JSONSchemaUseDefaultOnError     = 1 << 3,
} JSONSchemaOptions;

typedef enum
{
    JSONSchemaNodeDictionary,
    JSONSchemaNodeArray,
    JSONSchemaNodeString,
    JSONSchemaNodeNumber,
    JSONSchemaNodeBoolean,
    JSONSchemaNodeNull,
    // Any type except Dictionary, Array, and Null (unless JSONSchemaAllowNull is set)
    JSONSchemaNodeAnyLiteral,
    JSONSchemaNodeAny,
    JSONSchemaNodeUnrecognized
} JSONSchemaNodeType;

extern NSString * const JSONSchemaErrorDomain;
// An error userInfo key with the schema node that caused the validation failure
extern NSString * const JSONSchemaErrorSchemaNodeKey;
// An error userInfo key with the object that failed to validate
extern NSString * const JSONSchemaErrorFailingObjectKey;
// An error userInfo key with the dictionary key that was missing
extern NSString * const JSONSchemaErrorMissingEntryKey;
// An error userInfo key with an NSSet of dictionary keys that were unexpected (JSONSchemaErrorUnexpectedEntry)
extern NSString * const JSONSchemaErrorUnexpectedEntriesKey;

typedef enum
{
    // Occurs when the wrong type is encountered while verifying an object,
    JSONSchemaErrorWrongType,
    // Occurs when a dictionary contains an unspecified key (JSONSchemaStrictDictionaries only)
    JSONSchemaErrorUnexpectedEntry,
    // Occurs when a dictionary is missing an expected key
    JSONSchemaErrorMissingKey,
    // Occurs when the schema does not have a root node
    JSONSchemaErrorMissingRoot,
    // Occurs when the schema contains an invalid node type (null or unrecognized)
    JSONSchemaErrorInvalidSchemaNode,
    // Occurs when the schema has a container node without children
    JSONSchemaErrorUnspecifiedChild,
    // Occurs when an array is empty (JSONSchemaNonEmptyArray only)
    JSONSchemaErrorEmptyArray,
    // Occurs when a JSON example lacks any members for an array
    JSONSchemaErrorExampleHasEmptyArray,
    // Occurs when a JSON example has multiple members for an array
    JSONSchemaErrorExampleHasMultipleExamples,
    // Occurs when a JSON example has a non-JSON result
    JSONSchemaErrorExampleHasIncorrectType
} JSONSchemaErrorCode;

@interface JSONSchemaNode : NSObject

@property (nonatomic, readonly) JSONSchemaNodeType type;
@property (nonatomic, readonly) JSONSchemaOptions options;
// JSONSchemaNode for JSONSchemaNodeArray, NSDictionary<NSString, JSONSchemaNode> for JSONSchemaNodeDictionary, nil otherwise
@property (nonatomic, readonly) id child;
@property (nonatomic, readonly) id defaultValue;

+ (instancetype)stringNode;
+ (instancetype)optionalStringNode;
+ (instancetype)numberNode;
+ (instancetype)optionalNumberNode;
+ (instancetype)booleanNode;
+ (instancetype)optionalBooleanNode;
+ (instancetype)anyLiteralNode;
+ (instancetype)anyOptionalLiteralNode;
+ (instancetype)anyNode;
+ (instancetype)anyOptionalNode;

- (id)initWithType:(JSONSchemaNodeType)type;
- (id)initWithType:(JSONSchemaNodeType)type
           options:(JSONSchemaOptions)options;
- (id)initWithType:(JSONSchemaNodeType)type
           options:(JSONSchemaOptions)options
             child:(id)child;
- (id)initWithType:(JSONSchemaNodeType)type
           options:(JSONSchemaOptions)options
           default:(id)defaultValue;
- (id)initWithType:(JSONSchemaNodeType)type
           options:(JSONSchemaOptions)options
             child:(id)child
           default:(id)defaultValue;

@end

@interface JSONSchema : NSObject

- (id)initWithRootNode:(JSONSchemaNode *)root;

- (BOOL)checkObject:(id)object error:(NSError *__autoreleasing *)error;

/*
 * Transforms an object according to a schema, pruning unspecified keys from dictionaries
 * and replacing NSNull and invalid objects with the specified default values as
 * appropriate.
 */
- (id)transformObject:(id)object error:(NSError *__autoreleasing *)error;

/*
 * Recursively converts a plist object into a schema node. If given a JSONSchemaNode
 * instead, returns that node.
 */
+ (JSONSchemaNode *)nodeForObject:(id)object error:(NSError *__autoreleasing *)error;
/*
 * Creates a schema by converting a plist object into the root schema node.
 */
+ (JSONSchema *)schemaForObject:(id)object error:(NSError *__autoreleasing *)error;

@end
