//
//  JSONSchema.m
//  Wattpad
//
//  Created by R. Tony Goold on 2014-01-14.
//  Copyright (c) 2014 N/A. All rights reserved.
//

#import "JSONSchema.h"

NSString * const JSONSchemaErrorDomain = @"JSONSchemaErrorDomain";
NSString * const JSONSchemaErrorSchemaNodeKey = @"JSONSchemaErrorSchemaNode";
NSString * const JSONSchemaErrorFailingObjectKey = @"JSONSchemaErrorFailingObject";
NSString * const JSONSchemaErrorUnexpectedEntriesKey = @"JSONSchemaErrorUnexpectedEntries";
NSString * const JSONSchemaErrorMissingEntryKey = @"JSONSchemaErrorMissingEntry";

@implementation JSONSchemaNode

// Since JSONSchemaNodes are immutable, we can return the same instance every time in these convenience constructors
+ (instancetype)stringNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeString];
    });
    return node;
}

+ (instancetype)optionalStringNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeString options:JSONSchemaOptional];
    });
    return node;
}

+ (instancetype)numberNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeNumber];
    });
    return node;
}

+ (instancetype)optionalNumberNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeNumber options:JSONSchemaOptional];
    });
    return node;
}

+ (instancetype)booleanNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeBoolean];
    });
    return node;
}

+ (instancetype)optionalBooleanNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeBoolean options:JSONSchemaOptional];
    });
    return node;
}

+ (instancetype)anyLiteralNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeAnyLiteral];
    });
    return node;
}

+ (instancetype)anyOptionalLiteralNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeAnyLiteral options:JSONSchemaOptional];
    });
    return node;
}

+ (instancetype)anyNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeAny];
    });
    return node;
}

+ (instancetype)anyOptionalNode
{
    static dispatch_once_t onceToken;
    static JSONSchemaNode *node;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] initWithType:JSONSchemaNodeAny options:JSONSchemaOptional];
    });
    return node;
}

- (id)init
{
    return nil;
}

- (id)initWithType:(JSONSchemaNodeType)type
{
    return [self initWithType:type
                      options:0
                        child:nil];
}

- (id)initWithType:(JSONSchemaNodeType)type
           options:(JSONSchemaOptions)options
{
    return [self initWithType:type
                      options:options
                        child:nil];
}
- (id)initWithType:(JSONSchemaNodeType)type
           options:(JSONSchemaOptions)options
             child:(id)child
{
    return [self initWithType:type
                      options:options
                        child:child
                      default:nil];
}

- (id)initWithType:(JSONSchemaNodeType)type
           options:(JSONSchemaOptions)options
           default:(id)defaultValue
{
    return [self initWithType:type
                      options:options
                        child:nil
                      default:defaultValue];
}

- (id)initWithType:(JSONSchemaNodeType)type
           options:(JSONSchemaOptions)options
             child:(id)child
           default:(id)defaultValue
{
    self = [super init];
    if (self)
    {
        _type = type;
        _options = options;
        _defaultValue = defaultValue;
        if (type == JSONSchemaNodeDictionary)
        {
            if (!child)
                child = @{};

            if (![child isKindOfClass:[NSDictionary class]])
            {
                [NSException raise:NSInvalidArgumentException
                            format:@"Invalid JSON schema: Dictionary initialized with %@ as child", [child class]];
            }
            _child = [child copy];
        }
        else if (type == JSONSchemaNodeArray)
        {
            if (!child)
                child = [JSONSchemaNode anyNode];
            _child = child;
        }
        else if (child)
        {
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid JSON schema: Non-container initialized with %@ as child", [child class]];
        }
    }
    return self;
}

@end

// Note: This method will never return JSONSchemaNodeBoolean
static inline JSONSchemaNodeType NodeTypeForObject(id object)
{
    if ([object isKindOfClass:[NSDictionary class]])
        return JSONSchemaNodeDictionary;
    else if ([object isKindOfClass:[NSArray class]])
        return JSONSchemaNodeArray;
    else if ([object isKindOfClass:[NSString class]])
        return JSONSchemaNodeString;
    else if ([object isKindOfClass:[NSNumber class]])
        return JSONSchemaNodeNumber;
    else if ([object isKindOfClass:[NSNull class]])
        return JSONSchemaNodeNull;
    else
        return JSONSchemaNodeUnrecognized;
}

@interface JSONSchema ()
{
    JSONSchemaNode *_root;
}

- (BOOL)checkObject:(id)object withNode:(JSONSchemaNode *)node error:(NSError *__autoreleasing *)error;
- (BOOL)checkDictionary:(NSDictionary *)dictionary withNode:(JSONSchemaNode *)node error:(NSError *__autoreleasing *)error;
- (BOOL)checkArray:(NSArray *)array withNode:(JSONSchemaNode *)node error:(NSError *__autoreleasing *)error;

- (id)transformObject:(id)object withNode:(JSONSchemaNode *)node error:(NSError *__autoreleasing *)error;
- (NSDictionary *)transformDictionary:(NSDictionary *)dictionary withNode:(JSONSchemaNode *)node error:(NSError *__autoreleasing *)error;
- (NSArray *)transformArray:(NSArray *)array withNode:(JSONSchemaNode *)node error:(NSError *__autoreleasing *)error;

@end

@implementation JSONSchema

static void SetError(NSError *__autoreleasing *error, NSInteger code, NSDictionary *userInfo)
{
    if (error)
    {
        *error = [NSError errorWithDomain:JSONSchemaErrorDomain
                                     code:code
                                 userInfo:userInfo];
    }
}

// Returns the set of keys in dict not specified by node's dictionary child
static NSSet *UnspecifiedKeySet(NSDictionary *dict, JSONSchemaNode *node)
{
    if (node.type != JSONSchemaNodeDictionary || ![node.child isKindOfClass:[NSDictionary class]])
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"UnspecifiedKeySet must be called with a valid dictionary schema node"];
    }
    NSSet *allowed = [NSSet setWithArray:[node.child allKeys]];
    NSMutableSet *unspecified = [NSMutableSet setWithArray:[dict allKeys]];
    [unspecified minusSet:allowed];
    return unspecified;
}

- (id)initWithRootNode:(JSONSchemaNode *)root
{
    self = [super init];
    if (self)
    {
        _root = root;
    }
    return self;
}

- (BOOL)checkObject:(id)object error:(NSError *__autoreleasing *)error
{
    if (!_root)
    {
        SetError(error, JSONSchemaErrorMissingRoot, nil);
        return NO;
    }

    return [self checkObject:object withNode:_root error:error];
}

- (BOOL)checkObject:(id)object
           withNode:(JSONSchemaNode *)node
              error:(NSError *__autoreleasing *)error
{
    if (!object || [object isKindOfClass:[NSNull class]])
    {
        if (node.options & JSONSchemaOptional)
            return YES;
        if (!object)
            object = [NSNull null];
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: object };
        SetError(error, JSONSchemaErrorWrongType, info);
        return NO;
    }

    BOOL isNumeric = [object isKindOfClass:[NSNumber class]];
    BOOL isString = [object isKindOfClass:[NSString class]];
    BOOL valid = YES;
    NSInteger code = JSONSchemaErrorWrongType;
    switch (node.type) {
        case JSONSchemaNodeAny:
            return YES;
        case JSONSchemaNodeDictionary:
            return [self checkDictionary:object withNode:node error:error];
        case JSONSchemaNodeArray:
            return [self checkArray:object withNode:node error:error];
        case JSONSchemaNodeAnyLiteral:
            valid = isNumeric || isString;
            break;
        case JSONSchemaNodeString:
            valid = isString;
            break;
        case JSONSchemaNodeNumber:
        case JSONSchemaNodeBoolean:
            valid = isNumeric;
            break;
        default:
            valid = NO;
            code = JSONSchemaErrorInvalidSchemaNode;
    }
    if (valid)
        return YES;

    if (!object)
        object = [NSNull null];
    NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                            JSONSchemaErrorFailingObjectKey: object };
    SetError(error, code, info);
    return NO;
}

- (BOOL)checkDictionary:(NSDictionary *)dictionary
               withNode:(JSONSchemaNode *)node
                  error:(NSError *__autoreleasing *)error
{
    if (![dictionary isKindOfClass:[NSDictionary class]])
    {
        id object = dictionary ? dictionary : [NSNull null];
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: object };
        SetError(error, JSONSchemaErrorWrongType, info);
        return NO;
    }

    NSDictionary *child = node.child;
    if (!child)
    {
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: dictionary };
        SetError(error, JSONSchemaErrorUnspecifiedChild, info);
        return NO;
    }

    if (node.options & JSONSchemaStrictDictionaries)
    {
        NSSet *unexpected = UnspecifiedKeySet(dictionary, node);
        if ([unexpected count] > 0)
        {
            NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                    JSONSchemaErrorFailingObjectKey: dictionary,
                                    JSONSchemaErrorUnexpectedEntriesKey: unexpected };
            SetError(error, JSONSchemaErrorUnexpectedEntry, info);
            return NO;
        }
    }

    for (id key in [child allKeys])
    {
        JSONSchemaNode *childNode = child[key];
        if (![childNode isKindOfClass:[JSONSchemaNode class]])
        {
            NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                    JSONSchemaErrorFailingObjectKey: dictionary };
            SetError(error, JSONSchemaErrorInvalidSchemaNode, info);
            return NO;
        }

        id value = dictionary[key];
        if (value)
        {
            if (![self checkObject:value withNode:childNode error:error])
                return NO;
        }
        else if (!(childNode.options & JSONSchemaOptional))
        {
            NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                    JSONSchemaErrorFailingObjectKey: dictionary,
                                    JSONSchemaErrorMissingEntryKey: key };
            SetError(error, JSONSchemaErrorMissingKey, info);
            return NO;
        }
    }
    return YES;
}

- (BOOL)checkArray:(NSArray *)array
          withNode:(JSONSchemaNode *)node
             error:(NSError *__autoreleasing *)error
{
    
    if (![array isKindOfClass:[NSArray class]])
    {
        id object = array ? array : [NSNull null];
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: object };
        SetError(error, JSONSchemaErrorWrongType, info);
        return NO;
    }

    JSONSchemaNode *child = node.child;
    if (![child isKindOfClass:[JSONSchemaNode class]])
    {
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: array };
        NSInteger code = child ? JSONSchemaErrorInvalidSchemaNode : JSONSchemaErrorUnspecifiedChild;
        SetError(error, code, info);
        return NO;
    }

    if ((node.options & JSONSchemaNonEmptyArray) && [array count] == 0)
    {
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: array };
        SetError(error, JSONSchemaErrorEmptyArray, info);
        return NO;
    }

    for (id object in array)
    {
        if (![self checkObject:object withNode:child error:error])
            return NO;
    }
    return YES;
}

- (id)transformObject:(id)object error:(NSError *__autoreleasing *)error
{
    if (!_root)
    {
        SetError(error, JSONSchemaErrorMissingRoot, nil);
        return NO;
    }
    return [self transformObject:object withNode:_root error:error];
}

- (id)transformObject:(id)object
             withNode:(JSONSchemaNode *)node
                error:(NSError *__autoreleasing *)error
{
    if (!object || [object isKindOfClass:[NSNull class]])
    {
        if (node.options & (JSONSchemaOptional | JSONSchemaUseDefaultOnError))
            return node.defaultValue;

        if (!object)
            object = [NSNull null];
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: object };
        SetError(error, JSONSchemaErrorWrongType, info);
        return NO;
    }

    if (node.type == JSONSchemaNodeDictionary)
        return [self transformDictionary:object withNode:node error:error];
    else if (node.type == JSONSchemaNodeArray)
        return [self transformArray:object withNode:node error:error];
    else if ([self checkObject:object withNode:node error:error])
        return object;
    else if (node.options & JSONSchemaUseDefaultOnError)
        return node.defaultValue;
    else
        return nil;
}

- (NSDictionary *)transformDictionary:(NSDictionary *)dictionary
                             withNode:(JSONSchemaNode *)node
                                error:(NSError *__autoreleasing *)error
{
    if (![dictionary isKindOfClass:[NSDictionary class]])
    {
        if (node.options & JSONSchemaUseDefaultOnError)
            return node.defaultValue;
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: dictionary };
        SetError(error, JSONSchemaErrorWrongType, info);
        return nil;
    }

    if (node.options & JSONSchemaStrictDictionaries)
    {
        NSSet *unexpected = UnspecifiedKeySet(dictionary, node);
        if ([unexpected count] > 0)
        {
            NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                    JSONSchemaErrorFailingObjectKey: dictionary,
                                    JSONSchemaErrorUnexpectedEntriesKey: unexpected };
            SetError(error, JSONSchemaErrorUnexpectedEntry, info);
            return nil;
        }
    }

    NSDictionary *child = node.child;
    if (!child)
    {
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: dictionary };
        SetError(error, JSONSchemaErrorUnspecifiedChild, info);
        return NO;
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[dictionary count]];
    for (id key in [child allKeys])
    {
        JSONSchemaNode *childNode = child[key];
        if (![childNode isKindOfClass:[JSONSchemaNode class]])
        {
            NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                    JSONSchemaErrorFailingObjectKey: dictionary };
            SetError(error, JSONSchemaErrorInvalidSchemaNode, info);
            return nil;
        }

        id originalValue = dictionary[key];
        id transformedValue = [self transformObject:originalValue withNode:childNode error:error];
        if (transformedValue)
        {
            result[key] = transformedValue;
            continue;
        }
        else if (childNode.options & JSONSchemaUseDefaultOnError)
        {
            continue;
        }
        else if (childNode.options & JSONSchemaOptional)
        {
            // Only missing or NSNull counts as optional
            if (!originalValue || [originalValue isKindOfClass:[NSNull class]])
                continue;
        }
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: dictionary,
                                JSONSchemaErrorMissingEntryKey: key };
        SetError(error, JSONSchemaErrorMissingKey, info);
        return NO;
    }
    return result;
}

- (NSArray *)transformArray:(NSArray *)array
                   withNode:(JSONSchemaNode *)node
                      error:(NSError *__autoreleasing *)error
{
    if (![array isKindOfClass:[NSArray class]])
    {
        if (node.options & JSONSchemaUseDefaultOnError)
            return node.defaultValue;
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: array };
        SetError(error, JSONSchemaErrorWrongType, info);
        return nil;
    }

    JSONSchemaNode *child = node.child;
    if (![child isKindOfClass:[JSONSchemaNode class]])
    {
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: array };
        NSInteger code = child ? JSONSchemaErrorInvalidSchemaNode : JSONSchemaErrorUnspecifiedChild;
        SetError(error, code, info);
        return NO;
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[array count]];
    for (id object in array)
    {
        id value = [self transformObject:object withNode:child error:error];
        if (value)
        {
            [result addObject:value];
        }
        else if (!(child.options & JSONSchemaUseDefaultOnError))
        {
            return nil;
        }
    }
    if ((node.options & JSONSchemaNonEmptyArray) && [result count] == 0)
    {
        NSDictionary *info = @{ JSONSchemaErrorSchemaNodeKey: node,
                                JSONSchemaErrorFailingObjectKey: array };
        SetError(error, JSONSchemaErrorEmptyArray, info);
        return nil;
    }
    return result;
}

+ (JSONSchemaNode *)nodeForObject:(id)object error:(NSError *__autoreleasing *)error
{
    if ([object isKindOfClass:[JSONSchemaNode class]])
        return object;

    JSONSchemaNodeType type = NodeTypeForObject(object);
    switch (type)
    {
        case JSONSchemaNodeDictionary:
        {
            NSDictionary *dict = object;
            NSMutableDictionary *mapped = [NSMutableDictionary dictionaryWithCapacity:[dict count]];
            __block BOOL failed = NO;
            [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                JSONSchemaNode *childNode = [self nodeForObject:obj error:error];
                if (childNode)
                {
                    mapped[key] = childNode;
                }
                else
                {
                    *stop = YES;
                    failed = YES;
                }
            }];
            if (failed)
                return nil;
            else
                return [[JSONSchemaNode alloc] initWithType:type options:0 child:mapped];
        }
        case JSONSchemaNodeArray:
        {
            NSArray *array = object;
            // An array in a schema requires uniformity
            if ([array count] == 0)
            {
                if (error)
                {
                    *error = [NSError errorWithDomain:JSONSchemaErrorDomain
                                                 code:JSONSchemaErrorExampleHasEmptyArray
                                             userInfo:nil];
                }
                return nil;
            }
            else if ([array count] != 1U)
            {
                if (error)
                {
                    *error = [NSError errorWithDomain:JSONSchemaErrorDomain
                                                 code:JSONSchemaErrorExampleHasMultipleExamples
                                             userInfo:nil];
                }
                return nil;
            }
            JSONSchemaNode *child = [self nodeForObject:[array lastObject] error:error];
            if (!child)
                return nil;
            return [[JSONSchemaNode alloc] initWithType:JSONSchemaNodeArray options:0 child:child];
        }
        case JSONSchemaNodeString:
        case JSONSchemaNodeNumber:
        case JSONSchemaNodeBoolean:
        {
            return [[JSONSchemaNode alloc] initWithType:type];
        }
        default:
        {
            if (error)
            {
                *error = [NSError errorWithDomain:JSONSchemaErrorDomain
                                             code:JSONSchemaErrorExampleHasIncorrectType
                                         userInfo:nil];
            }
            return nil;
        }
    }
}

+ (JSONSchema *)schemaForObject:(id)object error:(NSError *__autoreleasing *)error
{
    JSONSchemaNode *root = [self nodeForObject:object error:error];
    return root ? [[JSONSchema alloc] initWithRootNode:root] : nil;
}

@end
