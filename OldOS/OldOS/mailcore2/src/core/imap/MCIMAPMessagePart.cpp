#include "MCIMAPMessagePart.h"

#include "MCDefines.h"

using namespace mailcore;

IMAPMessagePart::IMAPMessagePart()
{
    init();
}

IMAPMessagePart::IMAPMessagePart(IMAPMessagePart * other) : AbstractMessagePart(other)
{
    init();
    MC_SAFE_REPLACE_COPY(String, mPartID, other->mPartID);
}

IMAPMessagePart::~IMAPMessagePart()
{
    MC_SAFE_RELEASE(mPartID);
}

Object * IMAPMessagePart::copy()
{
    return new IMAPMessagePart(this);
}

void IMAPMessagePart::init()
{
    mPartID = NULL;
}

void IMAPMessagePart::setPartID(String * partID)
{
    MC_SAFE_REPLACE_COPY(String, mPartID, partID);
}

String * IMAPMessagePart::partID()
{
    return mPartID;
}

HashMap * IMAPMessagePart::serializable()
{
    HashMap * result = AbstractMessagePart::serializable();
    if (partID() != NULL) {
        result->setObjectForKey(MCSTR("partID"), partID());
    }
    return result;
}

void IMAPMessagePart::importSerializable(HashMap * serializable)
{
    AbstractMessagePart::importSerializable(serializable);
    String * partID = (String *) serializable->objectForKey(MCSTR("partID"));
    setPartID(partID);
}

static void * createObject()
{
    return new IMAPMessagePart();
}

INITIALIZE(IMAPMessagePart)
{
    Object::registerObjectConstructor("mailcore::IMAPMessagePart", &createObject);
}
