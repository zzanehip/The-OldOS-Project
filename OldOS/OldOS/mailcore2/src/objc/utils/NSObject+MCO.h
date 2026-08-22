//
//  NSObject+MCO.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_NSOBJECT_MCO_H

#define MAILCORE_NSOBJECT_MCO_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <typeinfo>
#endif

#ifdef __cplusplus
namespace mailcore {
    class Object;
}
#endif

#define MCO_NATIVE_INSTANCE ((nativeType *) [self mco_mcObject])

#define MCO_TO_OBJC(mcValue) \
    [NSObject mco_objectWithMCObject:((mailcore::Object *) (mcValue))]

#define MCO_FROM_OBJC(type, objcValue) \
    ((type *) [(objcValue) mco_mcObject])

#define MCO_OBJC_BRIDGE_SET(setter, mcValueType, objcValue) \
    MCO_NATIVE_INSTANCE->setter((mcValueType *) [(objcValue) mco_mcObject])

#define MCO_OBJC_BRIDGE_GET(getter) \
    [NSObject mco_objectWithMCObject:MCO_NATIVE_INSTANCE->getter()]

#define MCO_OBJC_SYNTHESIZE_TYPE(objcType, mcType, setter, getter) \
- (objcType *) getter \
{ \
return MCO_OBJC_BRIDGE_GET(getter); \
} \
\
- (void) setter:(objcType *)getter \
{ \
MCO_OBJC_BRIDGE_SET(setter, mcType, getter); \
}

#define MCO_OBJC_SYNTHESIZE(type, setter, getter) \
    MCO_OBJC_SYNTHESIZE_TYPE(MCO ## type, mailcore::type, setter, getter)

#define MCO_OBJC_SYNTHESIZE_SCALAR(objcType, mcType, setter, getter) \
- (objcType) getter \
{ \
return (objcType) MCO_NATIVE_INSTANCE->getter(); \
} \
\
- (void) setter:(objcType)getter \
{ \
MCO_NATIVE_INSTANCE->setter((mcType) getter); \
}

#define MCO_OBJC_SYNTHESIZE_STRING(setter, getter) MCO_OBJC_SYNTHESIZE_TYPE(NSString, mailcore::String, setter, getter)
#define MCO_OBJC_SYNTHESIZE_ARRAY(setter, getter) MCO_OBJC_SYNTHESIZE_TYPE(NSArray, mailcore::Array, setter, getter)
#define MCO_OBJC_SYNTHESIZE_DATA(setter, getter) MCO_OBJC_SYNTHESIZE_TYPE(NSData, mailcore::Data, setter, getter)
#define MCO_OBJC_SYNTHESIZE_HASHMAP(setter, getter) MCO_OBJC_SYNTHESIZE_TYPE(NSDictionary, mailcore::HashMap, setter, getter)
#define MCO_OBJC_SYNTHESIZE_BOOL(setter, getter) MCO_OBJC_SYNTHESIZE_SCALAR(BOOL, bool, setter, getter)

#define MCO_OBJC_SYNTHESIZE_DATE(setter, getter) \
- (NSDate *) getter \
{ \
    return [NSDate dateWithTimeIntervalSince1970:MCO_NATIVE_INSTANCE->getter()]; \
} \
\
- (void) setter:(NSDate *)getter \
{ \
    MCO_NATIVE_INSTANCE->setter([getter timeIntervalSince1970]); \
}

#define MCO_SYNTHESIZE_NSCODING \
- (instancetype) initWithCoder:(NSCoder *)coder \
{ \
  [self release]; \
  mailcore::HashMap * serializable = MCO_FROM_OBJC(mailcore::HashMap, [coder decodeObjectForKey:@"info"]); \
  self = MCO_TO_OBJC(mailcore::Object::objectWithSerializable(serializable)); \
  [self retain]; \
  return self; \
} \
\
- (void) encodeWithCoder:(NSCoder *)coder \
{ \
    [coder encodeObject:MCO_TO_OBJC(MCO_FROM_OBJC(nativeType, self)->serializable()) forKey:@"info"]; \
}

@interface NSObject (MCO)

#ifdef __cplusplus
+ (id) mco_objectWithMCObject:(mailcore::Object *)object;

- (mailcore::Object *) mco_mcObject;
#endif

@end

#ifdef __cplusplus
extern void MCORegisterClass(Class aClass, const std::type_info * info);
#endif

#endif
