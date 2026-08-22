//
//  MCPOPNoopOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 9/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCPOPNoopOperation.h"

#include "MCPOPAsyncSession.h"
#include "MCPOPSession.h"

using namespace mailcore;

POPNoopOperation::POPNoopOperation()
{
}

POPNoopOperation::~POPNoopOperation()
{
}

void POPNoopOperation::main()
{
    ErrorCode error;
    
    session()->session()->noop(&error);
    setError(error);
}
