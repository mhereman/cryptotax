function setTransactionType(selectElem) {
    let txtype = parseInt(selectElem.value);
    //refreshContent({ "txtype": txtype});
    loadTransactionTypePage(txtype);
}

function loadTransactionTypePage(txtype) {
    let page='';
    switch (txtype) {
        case 1:
            page = '/transactions/add/initialisation';
            break;
        case 2:
            page = '/transactions/add/trade';
            break;
        case 3:
            page = '/transactions/add/txfee';
            break;
    }
    if (page==='') {
        throw new Error('Invalid transaction type: '+txtype);
    }

    fetch (page)
        .then(response => {
            if (!response.ok) {
                throw new Error('Page not found');
            }
            return response.text();
        })
        .then(html => {
            setInnerHTML(document.getElementById('txtype-content'), html);
        })
        .catch(error => {
            document.getElementById('txtype-content').innerHTML = '<p style="color:red;">Error: '+error.Message+'</p>';
        });
}