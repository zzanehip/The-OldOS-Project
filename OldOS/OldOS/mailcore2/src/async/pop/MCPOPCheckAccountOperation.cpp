//
//  MCPOPCheckAccountOperation.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 4/6/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCPOPCheckAccountOperation.h"

#include "MCPOPAsyncSession.h"
#include "MCPOPSession.h"

using namespace mailcore;

POPCheckAccountOperation::POPCheckAccountOperation()
{
}

POPCheckAccountOperation::~POPCheckAccountOperation()
{
}

void POPCheckAccountOperation::main()
{
    ErrorCode error;
    
    session()->session()->checkAccount(&error);
    setError(error);
}
