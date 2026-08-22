//
//  NSString+MCO.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/21/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "NSString+MCO.h"

#include "MCString.h"

@implementation NSString (MCO)

+ (id) mco_objectWithMCObject:(mailcore::Object *)object
{
    return [self mco_stringWithMCString:(mailcore::String *) object];
}

+ (NSString *) mco_stringWithMCString:(mailcore::String *)cppString
{
    if (cppString == NULL)
        return nil;
    
    return [NSString stringWithCharacters:(const unichar *) cppString->unicodeCharacters() length:cppString->length()];
}

+ (NSString *) mco_stringWithMCObject:(mailcore::Object *)object
{
    if (object == NULL)
        return nil;
    
    return [NSString mco_stringWithMCString:object->description()];
}

- (mailcore::String *) mco_mcString
{
    const UChar * characters = (const UChar *) [self cStringUsingEncoding:NSUTF16StringEncoding];
    return mailcore::String::stringWithCharacters(characters, (unsigned int) [self length]);
}

- (NSString *) mco_flattenHTML
{
	return [NSString mco_stringWithMCString:[self mco_mcString]->flattenHTML()];
}

- (NSString *) mco_flattenHTMLAndShowBlockquote:(BOOL)showBlockquote
{
	return [NSString mco_stringWithMCString:[self mco_mcString]->flattenHTMLAndShowBlockquote(showBlockquote)];
}

- (NSString *) mco_flattenHTMLAndShowBlockquote:(BOOL)showBlockquote showLink:(BOOL)showLink
{
	return [NSString mco_stringWithMCString:[self mco_mcString]->flattenHTMLAndShowBlockquoteAndLink(showBlockquote, showLink)];
}


- (NSString *) mco_htmlEncodedString
{
	return [NSString mco_stringWithMCString:[self mco_mcString]->htmlEncodedString()];
}

- (NSString *) mco_cleanedHTMLString
{
	return [NSString mco_stringWithMCString:[self mco_mcString]->cleanedHTMLString()];
}

- (NSString *) mco_strippedWhitespace
{
    return [NSString mco_stringWithMCString:[self mco_mcString]->stripWhitespace()];
}

@end
