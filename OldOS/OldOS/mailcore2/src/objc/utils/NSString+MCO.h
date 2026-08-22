//
//  NSString+MCO.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/21/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_NSSTRING_MCO_H

#define MAILCORE_NSSTRING_MCO_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
namespace mailcore {
    class String;
    class Object;
}
#endif

@interface NSString (MCO)

#ifdef __cplusplus
+ (NSString *) mco_stringWithMCString:(mailcore::String *)cppString;
+ (NSString *) mco_stringWithMCObject:(mailcore::Object *)object;

- (mailcore::String *) mco_mcString;
#endif

- (NSString *) mco_flattenHTML;
- (NSString *) mco_flattenHTMLAndShowBlockquote:(BOOL)showBlockquote;
- (NSString *) mco_flattenHTMLAndShowBlockquote:(BOOL)showBlockquote showLink:(BOOL)showLink;

- (NSString *) mco_htmlEncodedString;
- (NSString *) mco_cleanedHTMLString;
- (NSString *) mco_strippedWhitespace;

@end

#endif
