#include "TypesUtils.h"

#include "MCValuePrivate.h"
#include "JavaHandle.h"
#include <libetpan/libetpan.h>
#include "MCDefines.h"
#include "MCLog.h"

using namespace mailcore;

static chash * cppClassHash = NULL;
static chash * javaClassHash = NULL;

#define RANGE_MAX (1ULL >> 63ULL - 1ULL)
#define LOCAL_FRAME_CAPACITY 32

static void init(void);
static void real_init(void);

jobject mailcore::rangeToJava(JNIEnv * env, Range range)
{
    jclass cls = env->FindClass("com/libmailcore/Range");
    jmethodID constructor = env->GetMethodID(cls, "<init>", "(JJ)V");
    jobject javaObject;
    if (range.length == UINT64_MAX) {
        javaObject = env->NewObject(cls, constructor, (jlong) range.location, (jlong) RANGE_MAX);
    }
    else {
        javaObject = env->NewObject(cls, constructor, (jlong) range.location, (jlong) range.length);
    }
    return javaObject;
}

Range mailcore::rangeFromJava(JNIEnv * env, jobject obj)
{
    jclass cls = env->GetObjectClass(obj);
    jfieldID locationField = env->GetFieldID(cls, "location", "J");
    jfieldID lengthField = env->GetFieldID(cls, "length", "J");
    jlong location = env->GetLongField(obj, locationField);
    jlong length = env->GetLongField(obj, lengthField);
    if (length == RANGE_MAX) {
        return RangeMake((uint64_t) location, UINT64_MAX);
    }
    else {
        return RangeMake((uint64_t) location, (uint64_t) length);
    }
}

time_t mailcore::javaDateToTime(JNIEnv * env, jobject date)
{
    jclass javaClass = env->GetObjectClass(date);
    jmethodID method = env->GetMethodID(javaClass, "getTime", "()J");
    jlong value = env->CallLongMethod(date, method);
    return (time_t) (value / 1000LL);
}

jobject mailcore::timeToJavaDate(JNIEnv * env, time_t t)
{
    jclass cls = env->FindClass("java/util/Date");
    jmethodID constructor = env->GetMethodID(cls, "<init>", "(J)V");
    jobject javaDate = env->NewObject(cls, constructor, ((jlong) t ) * 1000LL);
    return javaDate;
}

void mailcore::MCJNIRegisterNativeClass(const std::type_info * info, ObjectToJavaConverter converter)
{
    MCLog("MCJNIRegisterNativeClass");
    init();
    
    chashdatum key;
    chashdatum value;
    MCLog("info: %p", info);
#ifdef __LIBCPP_TYPEINFO
    size_t hash_value = info->hash_code();
    MCLog("info hash: %i", (int) hash_value);
    key.data = &hash_value;
    key.len = sizeof(hash_value);
#else
    MCLog("info name: %s", info->name());
    key.data = (void *) info->name();
    key.len = (unsigned int) strlen(info->name());
#endif
    value.data = (void *) converter;
    value.len = 0;
    chash_set(cppClassHash, &key, &value, NULL);
}

void mailcore::MCJNIRegisterJavaClass(const char * className, JavaToObjectConverter converter)
{
    MCLog("MCJNIRegisterJavaClass %s", className);
    init();
    
    chashdatum key;
    chashdatum value;
    key.data = (void *) className;
    key.len = strlen(className);
    value.data = (void *) converter;
    value.len = 0;
    chash_set(javaClassHash, &key, &value, NULL);
}

static jobject valueObjectToJavaConverter(JNIEnv * env, Object * obj)
{
    jclass cls;
    jmethodID constructor;
    Value * value = (Value *) obj;
    jobject result;
    switch (value->type()) {
        // boolean, byte, character, long, int, short, double, float
        case mailcore::ValueTypeNone:
        MCAssert(0);
        break;
        case mailcore::ValueTypeBool:
        // bool
        cls = env->FindClass("java/lang/Boolean");
        constructor = env->GetMethodID(cls, "<init>", "(Z)V");
        result = env->NewObject(cls, constructor, value->boolValue());
        break;
        case mailcore::ValueTypeChar:
        // byte
        cls = env->FindClass("java/lang/Byte");
        constructor = env->GetMethodID(cls, "<init>", "(B)V");
        result = env->NewObject(cls, constructor, value->charValue());
        break;
        case mailcore::ValueTypeUnsignedChar:
        // short
        cls = env->FindClass("java/lang/Short");
        constructor = env->GetMethodID(cls, "<init>", "(S)V");
        result = env->NewObject(cls, constructor, value->unsignedCharValue());
        break;
        case mailcore::ValueTypeShort:
        // short
        cls = env->FindClass("java/lang/Short");
        constructor = env->GetMethodID(cls, "<init>", "(S)V");
        result = env->NewObject(cls, constructor, value->shortValue());
        break;
        case mailcore::ValueTypeUnsignedShort:
        // int
        cls = env->FindClass("java/lang/Integer");
        constructor = env->GetMethodID(cls, "<init>", "(I)V");
        result = env->NewObject(cls, constructor, value->intValue());
        break;
        case mailcore::ValueTypeInt:
        // int
        cls = env->FindClass("java/lang/Integer");
        constructor = env->GetMethodID(cls, "<init>", "(I)V");
        result = env->NewObject(cls, constructor, value->intValue());
        break;
        case mailcore::ValueTypeUnsignedInt:
        // long
        cls = env->FindClass("java/lang/Long");
        constructor = env->GetMethodID(cls, "<init>", "(J)V");
        result = env->NewObject(cls, constructor, value->unsignedIntValue());
        break;
        case mailcore::ValueTypeLong:
        // long
        cls = env->FindClass("java/lang/Long");
        constructor = env->GetMethodID(cls, "<init>", "(J)V");
        result = env->NewObject(cls, constructor, value->longValue());
        break;
        case mailcore::ValueTypeUnsignedLong:
        // long
        cls = env->FindClass("java/lang/Long");
        constructor = env->GetMethodID(cls, "<init>", "(J)V");
        result = env->NewObject(cls, constructor, value->unsignedLongValue());
        break;
        case mailcore::ValueTypeLongLong:
        // long
        cls = env->FindClass("java/lang/Long");
        constructor = env->GetMethodID(cls, "<init>", "(J)V");
        result = env->NewObject(cls, constructor, value->longLongValue());
        break;
        case mailcore::ValueTypeUnsignedLongLong:
        // long - might break
        cls = env->FindClass("java/lang/Long");
        constructor = env->GetMethodID(cls, "<init>", "(J)V");
        result = env->NewObject(cls, constructor, value->unsignedLongLongValue());
        break;
        case mailcore::ValueTypeFloat:
        // float
        cls = env->FindClass("java/lang/Float");
        constructor = env->GetMethodID(cls, "<init>", "(F)V");
        result = env->NewObject(cls, constructor, value->floatValue());
        break;
        case mailcore::ValueTypeDouble:
        // double
        cls = env->FindClass("java/lang/Double");
        constructor = env->GetMethodID(cls, "<init>", "(D)V");
        result = env->NewObject(cls, constructor, value->doubleValue());
        break;
        case mailcore::ValueTypePointer:
        MCAssert(0);
        break;
        case mailcore::ValueTypeData:
        MCAssert(0);
        break;
    }
    return result;
}

static jobject dataObjectToJavaConverter(JNIEnv * env, Object * obj)
{
    Data * data = (Data *) obj;
    jbyteArray result = env->NewByteArray(data->length());
    env->SetByteArrayRegion(result, 0, (jsize) data->length(), (const jbyte *) data->bytes());
    return result;
}

static jobject stringObjectToJavaConverter(JNIEnv * env, Object * obj)
{
    String * str = (String *) obj;
    return env->NewString((const jchar *) str->unicodeCharacters(), (jsize) str->length());
}

static jobject hashmapObjectToJavaConverter(JNIEnv * env, Object * obj)
{
    HashMap * hashMap = (HashMap *) obj;
    jclass cls = env->FindClass("java/util/HashMap");
    jmethodID constructor = env->GetMethodID(cls, "<init>", "(I)V");
    jobject javaHashMap = env->NewObject(cls, constructor, hashMap->count());
    jmethodID method = env->GetMethodID(cls, "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
    Array * keys = hashMap->allKeys();
    for(unsigned int i = 0 ; i < keys->count() ; i ++) {
        env->PushLocalFrame(LOCAL_FRAME_CAPACITY);
        Object * key = keys->objectAtIndex(i);
        jobject javaKey = mcObjectToJava(env, key);
        Object * value = hashMap->objectForKey(key);
        jobject javaValue = mcObjectToJava(env, value);
        env->CallObjectMethod(javaHashMap, method, javaKey, javaValue);
        env->PopLocalFrame(NULL);
    }
    return javaHashMap;
}

static jobject arrayObjectToJavaConverter(JNIEnv * env, Object * obj)
{
    Array * array = (Array *) obj;
    jclass cls = env->FindClass("java/util/Vector");
    jmethodID constructor = env->GetMethodID(cls, "<init>", "(I)V");
    jobject javaVector = env->NewObject(cls, constructor, array->count());
    jmethodID method = env->GetMethodID(cls, "add", "(Ljava/lang/Object;)Z");
    MCLog("add method %p", method);
    for(unsigned int i = 0 ; i < array->count() ; i ++) {
        env->PushLocalFrame(LOCAL_FRAME_CAPACITY);
        MCLog("converting object %s", MCUTF8(array->objectAtIndex(i)));
        jobject javaObject = mcObjectToJava(env, array->objectAtIndex(i));
        MCLog("add object %p", javaObject);
        env->CallBooleanMethod(javaVector, method, javaObject);
        MCLog("added object %p", javaObject);
        env->PopLocalFrame(NULL);
    }
    MCLog("array converted");
    return javaVector;
}

static Object * booleanJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "booleanValue", "()B");
    jboolean value = env->CallBooleanMethod(obj, method);
    return Value::valueWithBoolValue(value);
}

static Object * byteJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "byteValue", "()B");
    jbyte value = env->CallByteMethod(obj, method);
    return Value::valueWithShortValue(value);
}

static Object * characterJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "charValue", "()C");
    jchar value = env->CallCharMethod(obj, method);
    return Value::valueWithShortValue(value);
}

static Object * longJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "longValue", "()J");
    jlong value = env->CallLongMethod(obj, method);
    return Value::valueWithLongLongValue(value);
}

static Object * integerJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "intValue", "()I");
    jint value = env->CallIntMethod(obj, method);
    return Value::valueWithIntValue(value);
}

static Object * shortJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "shortValue", "()S");
    jshort value = env->CallShortMethod(obj, method);
    return Value::valueWithShortValue(value);
}

static Object * doubleJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "doubleValue", "()D");
    jdouble value = env->CallDoubleMethod(obj, method);
    return Value::valueWithDoubleValue(value);
}

static Object * floatJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "floatValue", "()F");
    jfloat value = env->CallFloatMethod(obj, method);
    return Value::valueWithFloatValue(value);
}

static Object * dataJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jsize len = env->GetArrayLength((jarray) obj);
    jbyte * bytes = env->GetByteArrayElements((jbyteArray) obj, NULL);
    Data * result = Data::dataWithBytes((const char *) bytes, len);
    env->ReleaseByteArrayElements((jbyteArray) obj, bytes, 0);
    return result;
}

static Object * stringJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    jsize len = env->GetStringLength((jstring) obj);
    const jchar * chars = env->GetStringChars((jstring) obj, NULL);
    String * result = String::stringWithCharacters(chars, len);
    env->ReleaseStringChars((jstring) obj, chars);
    return result;
}

static bool isJavaMap(JNIEnv * env, jobject obj)
{
    jclass cls = env->FindClass("java/util/Map");
    return env->IsInstanceOf(obj, cls);
}

static Object * hashmapJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    env->PushLocalFrame(LOCAL_FRAME_CAPACITY);
    HashMap * result = HashMap::hashMap();
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "entrySet", "()Ljava/util/Set;");
    jobject entrySet = (jobjectArray) env->CallObjectMethod(obj, method);
    javaClass = env->GetObjectClass(entrySet);
    method = env->GetMethodID(javaClass, "toArray", "()[Ljava/lang/Object;");
    jobjectArray array = (jobjectArray) env->CallObjectMethod(entrySet, method);
    int count = (int) env->GetArrayLength(array);
    for(int i = 0 ; i < count ; i ++) {
        env->PushLocalFrame(LOCAL_FRAME_CAPACITY);
        jobject entry = env->GetObjectArrayElement(array, i);
        javaClass = env->GetObjectClass(entry);
        method = env->GetMethodID(javaClass, "getKey", "()Ljava/lang/Object;");
        jobject key = env->CallObjectMethod(entry, method);
        Object * mcKey = javaToMCObject(env, key);
        method = env->GetMethodID(javaClass, "getValue", "()Ljava/lang/Object;");
        jobject value = env->CallObjectMethod(entry, method);
        Object * mcValue = javaToMCObject(env, value);
        result->setObjectForKey(mcKey, mcValue);
        env->PopLocalFrame(NULL);
    }
    env->PopLocalFrame(NULL);
    return result;
}

static bool isJavaList(JNIEnv * env, jobject obj)
{
    jclass cls = env->FindClass("java/util/List");
    return env->IsInstanceOf(obj, cls);
}

static Object * arrayJavaToObjectConverter(JNIEnv * env, jobject obj)
{
    env->PushLocalFrame(LOCAL_FRAME_CAPACITY);
    Array * result = Array::array();
    jclass javaClass = env->GetObjectClass(obj);
    jmethodID method = env->GetMethodID(javaClass, "toArray", "()[Ljava/lang/Object;");
    jobjectArray array = (jobjectArray) env->CallObjectMethod(obj, method);
    int count = (int) env->GetArrayLength(array);
    for(int i = 0 ; i < count ; i ++) {
        jobject item = env->GetObjectArrayElement(array, i);
        Object * mcItem = javaToMCObject(env, item);
        env->DeleteLocalRef(item);
        result->addObject(mcItem);
    }
    env->PopLocalFrame(NULL);
    return result;
}

static bool isNativeObject(JNIEnv * env, jobject obj)
{
    jclass cls = env->FindClass("com/libmailcore/NativeObject");
    return env->IsInstanceOf(obj, cls);
}

static void setupBasicConverters(void)
{
    MCLog("register value");
    MCJNIRegisterNativeClass(&typeid(mailcore::Value), (ObjectToJavaConverter *) valueObjectToJavaConverter);
    MCLog("register data");
    MCJNIRegisterNativeClass(&typeid(mailcore::Data), (ObjectToJavaConverter *) dataObjectToJavaConverter);
    MCLog("register string");
    MCJNIRegisterNativeClass(&typeid(mailcore::String), (ObjectToJavaConverter *) stringObjectToJavaConverter);
    MCLog("register hashmap");
    MCJNIRegisterNativeClass(&typeid(mailcore::HashMap), (ObjectToJavaConverter *) hashmapObjectToJavaConverter);
    MCLog("register array");
    MCJNIRegisterNativeClass(&typeid(mailcore::Array), (ObjectToJavaConverter *) arrayObjectToJavaConverter);
    
    MCLog("register java bool");
    MCJNIRegisterJavaClass("java.lang.Boolean", (JavaToObjectConverter *) booleanJavaToObjectConverter);
    MCLog("register java byte");
    MCJNIRegisterJavaClass("java.lang.Byte", (JavaToObjectConverter *) byteJavaToObjectConverter);
    MCLog("register java char");
    MCJNIRegisterJavaClass("java.lang.Character", (JavaToObjectConverter *) characterJavaToObjectConverter);
    MCLog("register java long");
    MCJNIRegisterJavaClass("java.lang.Long", (JavaToObjectConverter *) longJavaToObjectConverter);
    MCLog("register java int");
    MCJNIRegisterJavaClass("java.lang.Integer", (JavaToObjectConverter *) integerJavaToObjectConverter);
    MCLog("register java short");
    MCJNIRegisterJavaClass("java.lang.Short", (JavaToObjectConverter *) shortJavaToObjectConverter);
    MCLog("register java double");
    MCJNIRegisterJavaClass("java.lang.Double", (JavaToObjectConverter *) doubleJavaToObjectConverter);
    MCLog("register java float");
    MCJNIRegisterJavaClass("java.lang.Float", (JavaToObjectConverter *) floatJavaToObjectConverter);
    MCLog("register java array of bytes");
    MCJNIRegisterJavaClass("[B", (JavaToObjectConverter *) dataJavaToObjectConverter);
    MCLog("register java string");
    MCJNIRegisterJavaClass("java.lang.String", (JavaToObjectConverter *) stringJavaToObjectConverter);
}

Object * mailcore::javaToMCObject(JNIEnv * env, jobject obj)
{
    if (obj == NULL) {
        return NULL;
    }
    
    if (isNativeObject(env, obj)) {
        return (Object *) getHandle(env, obj);
    }
    else if (isJavaMap(env, obj)) {
        return hashmapJavaToObjectConverter(env, obj);
    }
    else if (isJavaList(env, obj)) {
        return arrayJavaToObjectConverter(env, obj);
    }
    else {
        env->PushLocalFrame(LOCAL_FRAME_CAPACITY);
        Object * result = NULL;
        
        jclass javaClass = env->GetObjectClass(obj);
        jclass classClass = env->GetObjectClass(javaClass);
        jmethodID mid = env->GetMethodID(classClass, "getName", "()Ljava/lang/String;");
        jstring strObj = (jstring) env->CallObjectMethod(javaClass, mid);
        const char * str = env->GetStringUTFChars(strObj, NULL);
        MCLog("class: %s", str);
        chashdatum key;
        chashdatum value;
        key.data = (void *) str;
        key.len = strlen(str);
        int r = chash_get(javaClassHash, &key, &value);
        if (r == 0) {
            JavaToObjectConverter * converter = (JavaToObjectConverter *) value.data;
            result = converter(env, obj);
            MCLog("result: %s", MCUTF8(result));
        }
        else {
            MCLog("converter not found: %s", str);
            MCAssert(0);
        }
        env->ReleaseStringUTFChars(strObj, str);
        env->PopLocalFrame(NULL);

        return result;
    }
}

jobject mailcore::mcObjectToJava(JNIEnv * env, Object * obj)
{
    MCLog("converter to java: %s", MCUTF8(obj));
    if (obj == NULL) {
        return NULL;
    }
    
    const std::type_info * info = &typeid(* obj);
    chashdatum key;
    chashdatum value;
#ifdef __LIBCPP_TYPEINFO
    size_t hash_value = info->hash_code();
    MCLog("converter to java: %i", (int) hash_value);
    key.data = &hash_value;
    key.len = sizeof(hash_value);
#else
    key.data = (void *) info->name();
    key.len = (unsigned int) strlen(info->name());
#endif
    int r = chash_get(cppClassHash, &key, &value);
    if (r < 0) {
        MCLog("converter not found: %s", MCUTF8(obj));
        MCAssert(0);
    }
    ObjectToJavaConverter * converter = (ObjectToJavaConverter *) value.data;
    return converter(env, obj);
}

static void init(void)
{
    static pthread_once_t once = PTHREAD_ONCE_INIT;
    pthread_once(&once, real_init);
}

static void real_init(void)
{
    MCLog("real_init");
    MCLog("init cppClassHash");
    cppClassHash = chash_new(CHASH_DEFAULTSIZE, CHASH_COPYKEY);
    MCLog("init javaClassHash");
    javaClassHash = chash_new(CHASH_DEFAULTSIZE, CHASH_COPYKEY);
}

void mailcore::MCTypesUtilsInit(void)
{
    MCLog("basic converters");
    setupBasicConverters();
}
