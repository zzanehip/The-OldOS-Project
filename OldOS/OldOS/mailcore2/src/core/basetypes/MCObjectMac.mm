//
//  MCObjectMac.mm
//  mailcore2
//
//  Created by DINH Viêt Hoà on 5/4/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCObject.h"

#import <Foundation/Foundation.h>

#include "MCOObjectWrapper.h"

using namespace mailcore;

Object * Object::autorelease()
{
    [MCOObjectWrapper objectWrapperWithObject:this];
    this->release();
    return this;
}
