//
//  MCMessageParserMac.m
//  mailcore2
//
//  Created by Hoa V. DINH on 10/24/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCMessageParser.h"

#import <Foundation/Foundation.h>

#import "NSData+MCO.h"

using namespace mailcore;

MessageParser * MessageParser::messageParserWithData(CFDataRef data)
{
    MessageParser * parser = new MessageParser(data);
    return (MessageParser *) parser->autorelease();
}

MessageParser::MessageParser(CFDataRef data)
{
    init();
    
    setBytes((char *) [(NSData *) data bytes], (unsigned int) [(NSData *) data length]);
    mNSData = [(NSData *) data retain];
}

Data * MessageParser::dataFromNSData()
{
    return [(NSData *) mNSData mco_mcData];
}
