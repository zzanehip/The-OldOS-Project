#ifndef MAILCORE_MCARRAY_H

#define MAILCORE_MCARRAY_H

#include <MailCore/MCObject.h>

#ifdef __cplusplus

typedef struct carray_s carray;

namespace mailcore {
    
    class String;
    
    class MAILCORE_EXPORT Array : public Object {
    public:
        Array();
        virtual ~Array();
        
        static Array * array();
        static Array * arrayWithObject(Object * obj);
        
        virtual unsigned int count();
        virtual void addObject(Object * obj);
        virtual void removeObjectAtIndex(unsigned int idx);
        virtual void removeObject(Object * obj);
        virtual int indexOfObject(Object * obj);
        virtual Object * objectAtIndex(unsigned int idx) ATTRIBUTE_RETURNS_NONNULL;
        virtual void replaceObject(unsigned int idx, Object * obj);
        virtual void insertObject(unsigned int idx, Object * obj);
        virtual void removeAllObjects();
        
        virtual void addObjectsFromArray(Array * array);
        virtual Object * lastObject();
        virtual void removeLastObject();
        virtual bool containsObject(Object * obj);
        
        virtual Array * sortedArray(int (* compare)(void * a, void * b, void * context), void * context);
        virtual void sortArray(int (* compare)(void * a, void * b, void * context), void * context);
        virtual String * componentsJoinedByString(String * delimiter);
        
    public: // subclass behavior
        Array(Array * o);
        virtual String * description();
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        virtual bool isEqual(Object * otherObject);

    private:
        carray * mArray;
        void init();
    };
    
}

#endif

#endif
