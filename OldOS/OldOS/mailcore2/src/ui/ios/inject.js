function scanInlineImages() {
    var imgTags = document.getElementsByTagName('img');
    var inlineImages = [];
    for (var i = 0; i < imgTags.length; i++) {
        if (imgTags[i].src.includes("cid:") == true) {
            inlineImages.push(
                {
                    "url": imgTags[i].src
                }
            );
            imgTags[i].id = imgTags[i].src;
        }
    }

    let jobj = JSON.stringify(inlineImages);
    window.location = 'com.libmailcore.macExample://open?params=' + jobj.toString();
};

function updateImageUrl(params) {
    var img = document.getElementById(params.id);
    img.setAttribute('src', params.url);
};