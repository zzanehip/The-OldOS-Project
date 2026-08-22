#include <MailCore/MailCore.h>
#include <dirent.h>
#include <math.h>
#include <time.h>

using namespace mailcore;

static int global_failure = 0;
static int global_success = 0;

static time_t referenceDate(void)
{
    struct tm aTm;
    memset(&aTm, 0, sizeof(aTm));
    aTm.tm_sec = 0;
    aTm.tm_min = 0;
    aTm.tm_hour = 16;
    aTm.tm_mday = 31;
    aTm.tm_mon = 11;
    aTm.tm_year = 2000 - 1900;
    time_t date = mktime(&aTm);
    return date;
}

static void testMessageBuilder1(String * path)
{
    printf("testMessageBuilder1\n");
    MessageBuilder * builder = new MessageBuilder();
    builder->header()->setFrom(Address::addressWithRFC822String(MCSTR("Hoà <dinh.viet.hoa@gmail.com>")));
    builder->header()->setTo(Array::arrayWithObject(Address::addressWithRFC822String(MCSTR("Foo Bar <dinh.viet.hoa@gmail.com>"))));
    builder->header()->setSubject(MCSTR("testMessageBuilder1"));
    builder->header()->setDate(referenceDate());
    builder->header()->setMessageID(MCSTR("MyMessageID123@mail.gmail.com"));
    builder->setHTMLBody(MCSTR("<html><body>This is a HTML content</body></html>"));
    Array * boundaries = Array::array();
    boundaries->addObject(MCSTR("1"));
    boundaries->addObject(MCSTR("2"));
    boundaries->addObject(MCSTR("3"));
    boundaries->addObject(MCSTR("4"));
    boundaries->addObject(MCSTR("5"));
    builder->setBoundaries(boundaries);
    String * outputPath = path->stringByAppendingPathComponent(MCSTR("output/builder1.eml"));
    Data * expectedData = Data::dataWithContentsOfFile(outputPath);
    if (!builder->data()->isEqual(expectedData)) {
        printf("testMessageBuilder1 failed\n");
        fprintf(stderr, "current:\n%s\n", MCUTF8(builder->data()->stringWithCharset("utf-8")));
        fprintf(stderr, "expected:\n%s\n", MCUTF8(expectedData->stringWithCharset("utf-8")));
        global_failure ++;
        return;
    }
    printf("testMessageBuilder1 ok\n");
    global_success ++;
}

static void testMessageBuilder2(String * path)
{
    printf("testMessageBuilder2\n");
    MessageBuilder * builder = new MessageBuilder();
    builder->header()->setFrom(Address::addressWithRFC822String(MCSTR("Hoà <dinh.viet.hoa@gmail.com>")));
    Array * to = Array::array();
    to->addObject(Address::addressWithRFC822String(MCSTR("Foo Bar <dinh.viet.hoa@gmail.com>")));
    to->addObject(Address::addressWithRFC822String(MCSTR("Other Recipient <another-foobar@to-recipient.org>")));
    builder->header()->setTo(to);
    Array * cc = Array::array();
    cc->addObject(Address::addressWithRFC822String(MCSTR("Carbon Copy <dinh.viet.hoa@gmail.com>")));
    cc->addObject(Address::addressWithRFC822String(MCSTR("Other Recipient <another-foobar@to-recipient.org>")));
    builder->header()->setCc(cc);
    builder->header()->setSubject(MCSTR("testMessageBuilder2"));
    builder->header()->setDate(referenceDate());
    builder->header()->setMessageID(MCSTR("MyMessageID123@mail.gmail.com"));
    builder->setHTMLBody(MCSTR("<html><body>This is a HTML content</body></html>"));
    String * attachmentPath = path->stringByAppendingPathComponent(MCSTR("input/photo.jpg"));
    builder->addAttachment(Attachment::attachmentWithContentsOfFile(attachmentPath));
    attachmentPath = path->stringByAppendingPathComponent(MCSTR("input/photo2.jpg"));
    builder->addAttachment(Attachment::attachmentWithContentsOfFile(attachmentPath));
    Array * boundaries = Array::array();
    boundaries->addObject(MCSTR("1"));
    boundaries->addObject(MCSTR("2"));
    boundaries->addObject(MCSTR("3"));
    boundaries->addObject(MCSTR("4"));
    boundaries->addObject(MCSTR("5"));
    builder->setBoundaries(boundaries);
    String * outputPath = path->stringByAppendingPathComponent(MCSTR("output/builder2.eml"));
    Data * expectedData = Data::dataWithContentsOfFile(outputPath);
    if (!builder->data()->isEqual(expectedData)) {
        printf("testMessageBuilder2 failed\n");
        fprintf(stderr, "current:\n%s\n", MCUTF8(builder->data()->stringWithCharset("utf-8")));
        fprintf(stderr, "expected:\n%s\n", MCUTF8(expectedData->stringWithCharset("utf-8")));
        global_failure ++;
        return;
    }
    printf("testMessageBuilder2 ok\n");
    global_success ++;
}

static void testMessageBuilder3(String * path)
{
    printf("testMessageBuilder3\n");
    MessageBuilder * builder = new MessageBuilder();
    builder->header()->setFrom(Address::addressWithRFC822String(MCSTR("Hoà <dinh.viet.hoa@gmail.com>")));
    Array * to = Array::array();
    to->addObject(Address::addressWithRFC822String(MCSTR("Foo Bar <dinh.viet.hoa@gmail.com>")));
    to->addObject(Address::addressWithRFC822String(MCSTR("Other Recipient <another-foobar@to-recipient.org>")));
    builder->header()->setTo(to);
    Array * cc = Array::array();
    cc->addObject(Address::addressWithRFC822String(MCSTR("Carbon Copy <dinh.viet.hoa@gmail.com>")));
    cc->addObject(Address::addressWithRFC822String(MCSTR("Other Recipient <another-foobar@to-recipient.org>")));
    builder->header()->setCc(cc);
    builder->header()->setSubject(MCSTR("testMessageBuilder3"));
    builder->header()->setDate(referenceDate());
    builder->header()->setMessageID(MCSTR("MyMessageID123@mail.gmail.com"));
    builder->setHTMLBody(MCSTR("<html><body><div>This is a HTML content</div><div><img src=\"cid:123\"></div></body></html>"));
    String * attachmentPath = path->stringByAppendingPathComponent(MCSTR("input/photo.jpg"));
    builder->addAttachment(Attachment::attachmentWithContentsOfFile(attachmentPath));
    attachmentPath = path->stringByAppendingPathComponent(MCSTR("input/photo2.jpg"));
    Attachment * attachment = Attachment::attachmentWithContentsOfFile(attachmentPath);
    attachment->setContentID(MCSTR("123"));
    builder->addRelatedAttachment(attachment);
    Array * boundaries = Array::array();
    boundaries->addObject(MCSTR("1"));
    boundaries->addObject(MCSTR("2"));
    boundaries->addObject(MCSTR("3"));
    boundaries->addObject(MCSTR("4"));
    boundaries->addObject(MCSTR("5"));
    builder->setBoundaries(boundaries);
    String * outputPath = path->stringByAppendingPathComponent(MCSTR("output/builder3.eml"));
    Data * expectedData = Data::dataWithContentsOfFile(outputPath);
    if (!builder->data()->isEqual(expectedData)) {
        printf("testMessageBuilder3 failed\n");
        fprintf(stderr, "current:\n%s\n", MCUTF8(builder->data()->stringWithCharset("utf-8")));
        fprintf(stderr, "expected:\n%s\n", MCUTF8(expectedData->stringWithCharset("utf-8")));
        global_failure ++;
        return;
    }
    printf("testMessageBuilder3 ok\n");
    global_success ++;
}

static Array * pathsInDirectory(String * directory)
{
    Array * result = Array::array();

    DIR * dir = opendir(directory->fileSystemRepresentation());
    if (dir == NULL) {
        return result;
    }

    struct dirent * ent;
    while ((ent = readdir(dir)) != NULL) {
        if (ent->d_name[0] == '.') {
            continue;
        }

        String * subpath = directory->stringByAppendingPathComponent(String::stringWithFileSystemRepresentation(ent->d_name));
        if (ent->d_type == DT_DIR) {
            result->addObjectsFromArray(pathsInDirectory(subpath));
        }
        else {
            result->addObject(subpath);
        }
    }
    closedir(dir);

    return result;
}

static void prepareHeaderForUnitTest(MessageHeader * header)
{
    time_t now = time(NULL);
    if (fabs((double) (now - header->date())) <= 2) {
        // Date might be generated, set to known date.
        header->setDate(referenceDate());
    }
    if (fabs((double) (header->receivedDate() - now)) <= 2) {
        // Date might be generated, set to known date.
        header->setReceivedDate(referenceDate());
    }
    if (header->isMessageIDAutoGenerated()) {
        header->setMessageID(MCSTR("MyMessageID123@mail.gmail.com"));
    }
}

static void preparePartForUnitTest(AbstractPart * part)
{
    if (part->className()->isEqual(MCSTR("mailcore::Multipart"))) {
        Multipart * multipart = (Multipart *) part;
        for(unsigned int i = 0 ; i < multipart->parts()->count() ; i ++) {
            preparePartForUnitTest((AbstractPart *) multipart->parts()->objectAtIndex(i));
        }
    }
    else if (part->className()->isEqual(MCSTR("mailcore::MessagePart"))) {
        prepareHeaderForUnitTest(((MessagePart *) part)->header());
        preparePartForUnitTest(((MessagePart *) part)->mainPart());
    }
}

static void testMessageParser(String * path)
{
    printf("testMessageParser\n");
    String * inputPath = path->stringByAppendingPathComponent(MCSTR("input"));
    String * outputPath = path->stringByAppendingPathComponent(MCSTR("output"));
    Array * list = pathsInDirectory(inputPath);
    int failure = 0;
    int success = 0;
    mc_foreacharray(String, filename, list) {
        MessageParser * parser = MessageParser::messageParserWithContentsOfFile(filename);
        prepareHeaderForUnitTest(parser->header());
        preparePartForUnitTest(parser->mainPart());
        HashMap * result = parser->serializable();
        String * expectedPath = outputPath->stringByAppendingPathComponent(filename->substringFromIndex(inputPath->length()));
        //fprintf(stderr, "expected: %s\n", MCUTF8(expectedPath));
        HashMap * expectedResult = (HashMap *) JSON::objectFromJSONData(Data::dataWithContentsOfFile(expectedPath));
        if (result->isEqual(expectedResult)) {
            success ++;
        }
        else {
            fprintf(stderr, "testMessageParser: failed for %s\n", MCUTF8(filename));
            fprintf(stderr, "expected: %s\n", MCUTF8(expectedResult));
            fprintf(stderr, "got: %s\n", MCUTF8(result));
            failure ++;
        }
    }
    if (failure > 0) {
        printf("testMessageParser ok: %i succeeded, %i failed\n", success, failure);
        global_failure ++;
        return;
    }
    printf("testMessageParser ok: %i succeeded\n", success);
    global_success ++;
}

static void testCharsetDetection(String * path)
{
    printf("testCharsetDetection\n");
    String * inputPath = path->stringByAppendingPathComponent(MCSTR("input"));
    Array * list = pathsInDirectory(inputPath);
    int failure = 0;
    int success = 0;
    mc_foreacharray(String, filename, list) {
        Data * data = Data::dataWithContentsOfFile(filename);
        String * charset = data->charsetWithFilteredHTML(false);
        charset = charset->lowercaseString();
        if (!filename->lastPathComponent()->stringByDeletingPathExtension()->isEqual(charset)) {
            failure ++;
            fprintf(stderr, "testCharsetDetection: failed for %s\n", MCUTF8(filename));
            fprintf(stderr, "got: %s\n", MCUTF8(charset));
        }
        else {
            success ++;
        }
    }
    if (failure > 0) {
        printf("testCharsetDetection ok: %i succeeded, %i failed\n", success, failure);
        global_failure ++;
        return;
    }
    printf("testCharsetDetection ok: %i succeeded\n", success);
    global_success ++;
}

static String * tweakDateFromSummary(String * summary) {
    Array * components = summary->componentsSeparatedByString(MCSTR("\n"));
    mc_foreacharray(String, line, components) {
        if (line->hasPrefix(MCSTR("Date:"))) {
            line->replaceOccurrencesOfString(MCSTR(" at "), MCSTR(" "));
        }
    }
    return components->componentsJoinedByString(MCSTR("\n"));
}

static void testSummary(String * path)
{
    printf("testSummary\n");
    String * inputPath = path->stringByAppendingPathComponent(MCSTR("input"));
    String * outputPath = path->stringByAppendingPathComponent(MCSTR("output"));
    Array * list = pathsInDirectory(inputPath);
    int failure = 0;
    int success = 0;
    mc_foreacharray(String, filename, list) {
        MessageParser * parser = MessageParser::messageParserWithContentsOfFile(filename);
        prepareHeaderForUnitTest(parser->header());
        preparePartForUnitTest(parser->mainPart());
        String * str = parser->plainTextRendering();
        String * resultPath = outputPath->stringByAppendingPathComponent(filename->substringFromIndex(inputPath->length()));
        resultPath = resultPath->stringByDeletingPathExtension()->stringByAppendingString(MCSTR(".txt"));
        Data * resultData = Data::dataWithContentsOfFile(resultPath);
        if (resultData == NULL) {
            fprintf(stderr, "test %s is a well-known failing test", MCUTF8(filename));
            continue;
        }
        String * resultString = resultData->stringWithCharset("utf-8");
        str = tweakDateFromSummary(str);
        resultString = tweakDateFromSummary(resultString);

        if (!resultString->isEqual(str)) {
            failure ++;
            fprintf(stderr, "testSummary: failed for %s\n", MCUTF8(filename));
            fprintf(stderr, "got: %s\n", MCUTF8(str));
            fprintf(stderr, "expected: %s\n", MCUTF8(resultData->stringWithCharset("utf-8")));
        }
        else {
            success ++;
        }
    }
    if (failure > 0) {
        printf("testSummary ok: %i succeeded, %i failed\n", success, failure);
        global_failure ++;
        return;
    }
    printf("testSummary ok: %i succeeded\n", success);
    global_success ++;
}

static void testMUTF7(void)
{
    int failure = 0;
    int success = 0;
    const char * mutf7string = "~peter/mail/&U,BTFw-/&ZeVnLIqe-";
    IMAPNamespace * ns = IMAPNamespace::namespaceWithPrefix(MCSTR(""), '/');
    Array * result = ns->componentsFromPath(String::stringWithUTF8Characters(mutf7string));
    if (strcmp(MCUTF8(result), "[~peter,mail,台北,日本語]") != 0) {
        failure ++;
    }
    else {
        success ++;
    }
    if (failure > 0) {
        printf("testMUTF7 ok: %i succeeded, %i failed\n", success, failure);
        global_failure ++;
        return;
    }
    printf("testMUTF7 ok: %i succeeded\n", success);
    global_success ++;
}

int main(int argc, char ** argv)
{
    setenv("TZ", "EST8EDT", 1);
    tzset();

    if (argc < 2) {
        fprintf(stderr, "syntax: unittestcpp [unittestdatadir]\n");
        exit(EXIT_FAILURE);
    }

    AutoreleasePool * pool = new AutoreleasePool();

    String * path = String::stringWithUTF8Characters(argv[1]);
    MCAssert(path != NULL);
    printf("data path: %s\n", MCUTF8(path));

    testMessageBuilder1(path->stringByAppendingPathComponent(MCSTR("builder")));
    testMessageBuilder2(path->stringByAppendingPathComponent(MCSTR("builder")));
    testMessageBuilder3(path->stringByAppendingPathComponent(MCSTR("builder")));
    testMessageParser(path->stringByAppendingPathComponent(MCSTR("parser")));
    testCharsetDetection(path->stringByAppendingPathComponent(MCSTR("charset-detection")));
    testSummary(path->stringByAppendingPathComponent(MCSTR("summary")));
    testMUTF7();

    printf("%i tests succeeded, %i tests failed\n", global_success, global_failure);

    pool->release();

    if (global_failure > 0) {
        exit(EXIT_FAILURE);
    }

    exit(EXIT_SUCCESS);
}