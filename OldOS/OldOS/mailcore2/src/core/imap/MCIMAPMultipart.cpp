#include "MCIMAPMultipart.h"

#include "MCDefines.h"

using namespace mailcore;

IMAPMultipart::IMAPMultipart()
{
    init();
}

IMAPMultipart::IMAPMultipart(IMAPMultipart * other) : AbstractMultipart(other)
{
    init();
    MC_SAFE_REPLACE_COPY(String, mPartID, other->mPartID);
}

IMAPMultipart::~IMAPMultipart()
{
    MC_SAFE_RELEASE(mPartID);
}

Object * IMAPMultipart::copy()
{
    return new IMAPMultipart(this);
}

void IMAPMultipart::init()
{
    mPartID = NULL;
}

void IMAPMultipart::setPartID(String * partID)
{
    MC_SAFE_REPLACE_COPY(String, mPartID, partID);
}

String * IMAPMultipart::partID()
{
    return mPartID;
}

HashMap * IMAPMultipart::serializable()
{
    HashMap * result = AbstractMultipart::serializable();
    if (partID() != NULL) {
        result->setObjectForKey(MCSTR("partID"), partID());
    }
    return result;
}

void IMAPMultipart::importSerializable(HashMap * serializable)
{
    AbstractMultipart::importSerializable(serializable);
    String * partID = (String *) serializable->objectForKey(MCSTR("partID"));
    setPartID(partID);
}

static void * createObject()
{
    return new IMAPMultipart();
}

INITIALIZE(IMAPMultipart)
{
    Object::registerObjectConstructor("mailcore::IMAPMultipart", &createObject);
}

