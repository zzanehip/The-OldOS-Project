#include "MCDataDecoderUtils.h"

#include <libetpan/libetpan.h>

#include <string.h>
#include <strings.h>

namespace mailcore {

static size_t uudecode(const char * text, size_t size, char * dst, size_t dst_buf_size)
{
    unsigned int count = 0;
    const char *b = text;		/* beg */
    const char *s = b;			/* src */
    const char *e = b+size;			/* end */
    char *d = dst;
    int out = (*s++ & 0x7f) - 0x20;

    /* don't process lines without leading count character */
    if (out < 0)
        return size;

    /* dummy check. user must allocate buffer with appropriate length */
    if (dst_buf_size < out)
        return size;

    /* don't process begin and end lines */
    if ((strncasecmp((const char *)b, "begin ", 6) == 0) ||
        (strncasecmp((const char *)b, "end",    3) == 0))
        return size;

    while (s < e && count < out)
    {
        int v = 0;
        int i;
        for (i = 0; i < 4; i += 1) {
            char c = *s++;
            v = v << 6 | ((c - 0x20) & 0x3F);
        }
        for (i = 2; i >= 0; i -= 1) {
            char c = (char) (v & 0xFF);
            d[i] = c;
            v = v >> 8;
        }
        d += 3;
        count += 3;
    }
    return count;
}

static void decodedPartDeallocator(char * decoded, unsigned int decoded_length) {
    mailmime_decoded_part_free(decoded);
}

Data * MCDecodeData(Data * encodedData, Encoding encoding, bool partialContent, Data ** pRemainingData)
{
    const char * text;
    size_t text_length;

    text = encodedData->bytes();
    text_length = encodedData->length();

    * pRemainingData = NULL;

    switch (encoding) {
        case Encoding7Bit:
        case Encoding8Bit:
        case EncodingBinary:
        case EncodingOther:
        default:
        {
            return encodedData;
        }
        case EncodingBase64:
        case EncodingQuotedPrintable:
        {
            char * decoded;
            size_t decoded_length;
            size_t cur_token;
            int mime_encoding;

            switch (encoding) {
                default: //disable warning
                case EncodingBase64:
                    mime_encoding = MAILMIME_MECHANISM_BASE64;
                    break;
                case EncodingQuotedPrintable:
                    mime_encoding = MAILMIME_MECHANISM_QUOTED_PRINTABLE;
                    break;
            }

            cur_token = 0;
            if (partialContent) {
                mailmime_part_parse_partial(text, text_length, &cur_token,
                                            mime_encoding, &decoded, &decoded_length);
            }
            else {
                mailmime_part_parse(text, text_length, &cur_token,
                                    mime_encoding, &decoded, &decoded_length);
            }

            if (cur_token < text_length) {
                * pRemainingData = Data::dataWithBytes(text + cur_token, (unsigned int)(text_length - cur_token));
            }

            Data * data = Data::data();
            data->takeBytesOwnership(decoded, (unsigned int) decoded_length, decodedPartDeallocator);
            return data;
        }
        case EncodingUUEncode:
        {
            Data * data;
            const char * current_p;

            data = Data::dataWithCapacity((unsigned int) text_length);

            current_p = text;
            while (1) {
                /* In uuencoded files each data line usually have 45 bytes of decoded data.
                 Maximum possible length is limited by (0x7f-0x20) bytes.
                 So 256-bytes buffer is enough. */
                char decoded_buf[256];
                size_t decoded_length;
                size_t length;
                const char * p;
                const char * p1;
                const char * p2;
                const char * end_line;

                p1 = strchr(current_p, '\n');
                p2 = strchr(current_p, '\r');
                if (p1 == NULL) {
                    p = p2;
                }
                else if (p2 == NULL) {
                    p = p1;
                }
                else {
                    if (p1 - current_p < p2 - current_p) {
                        p = p1;
                    }
                    else {
                        p = p2;
                    }
                }
                end_line = p;
                if (partialContent && (p1 == NULL || p2 == NULL) &&
                    ((end_line == NULL) || (end_line - text) == (text_length - 1))) {
                    // possibly partial content detected
                    * pRemainingData = Data::dataWithBytes(current_p, (unsigned int)(text_length - (current_p - text)));
                    break;
                }
                if (p != NULL) {
                    while ((size_t) (p - text) < text_length) {
                        if ((* p != '\r') && (* p != '\n')) {
                            break;
                        }
                        p ++;
                    }
                }
                if (p == NULL) {
                    length = text_length - (current_p - text);
                }
                else {
                    length = end_line - current_p;
                }
                if (length == 0) {
                    break;
                }
                decoded_length = uudecode(current_p, length, decoded_buf, sizeof(decoded_buf));
                if (decoded_length != 0 && decoded_length < length) {
                    data->appendBytes(decoded_buf, (unsigned int) decoded_length);
                }

                if (p == NULL)
                    break;

                current_p = p;
                while ((size_t) (current_p - text) < text_length) {
                    if ((* current_p != '\r') && (* current_p != '\n')) {
                        break;
                    }
                    current_p ++;
                }
            }
            
            return data;
        }
    }
}

}
