var currentPage;

function loadContent(page, category, label) {
    fetch (page)
        .then(response => {
            if (!response.ok) {
                throw new Error('Page not found');
            }
            return response.text();
        })
        .then(html => {
            setInnerHTML(document.getElementById('content'), html);
        })
        .catch(error => {
            document.getElementById('content').innerHTML = '<p style="color:red;">Error: ' + error.message + '</p>';
        });

    currentPage = page;

    // Set all anchors with id prefix cat_ to inactive
    var anchors = document.querySelectorAll('a[id^="cat_"]');
    for (var i = 0; i < anchors.length; i++) {
        anchors[i].classList.remove('active');
    }

    // Mark the current category as active
    document.getElementById('cat_' + category).classList.add('active');

    // Set all anchors with id prefix page_ to inactive
    var anchors = document.querySelectorAll('a[id^="page"]');
    for (var i = 0; i < anchors.length; i++) {
        anchors[i].classList.remove('active');
    }
    
    // Mark the current page as active
    document.getElementById('page' + label).classList.add('active');
}

function refreshContent(args) {
    let url = currentPage;
    let argCnt=0;
    for (const property in args) {
        let sep = argCnt === 0 ? '?' : '&';
        argCnt++;
        url += sep + property + '=' + args[property];
    }

    fetch (url)
        .then(response => {
            if (!response.ok) {
                throw new Error('Page not found');
            }
            return response.text();
        })
        .then(html => {
            setInnerHTML(document.getElementById('content'), html);
            //document.getElementById('content').innerHTML= html;
        })
        .catch(error => {
            document.getElementById('content').innerHTML = '<p style="color:red;">Error: ' + error.message + '</p>';
        });
}