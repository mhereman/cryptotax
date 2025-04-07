function incrementYear() {
    let year = parseInt(document.getElementById("year").innerHTML);
    year++;
    let pagesize = getSelectedPageSize();
    refreshContent({ "year": year, "pagesize": pagesize }); 
}

function decrementYear() {
    let year = parseInt(document.getElementById("year").innerHTML);
    year--;
    let pagesize = getSelectedPageSize();
    refreshContent({ "year": year, "pagesize": pagesize });
}

function setPage(page) {
    let year = parseInt(document.getElementById("year").innerHTML);
    let pagesize = getSelectedPageSize();
    refreshContent({ "year": year, "page": page, "pagesize": pagesize });
}

function setPageSize(selectElem) {
    let year = parseInt(document.getElementById("year").innerHTML);
    let pagesize = parseInt(selectElem.value);
    refreshContent({ "year": year, "pagesize": pagesize });
}

function getSelectedPageSize() {
    let sel = new mdc.select.MDCSelect(document.getElementById("selPageSize"));
    return parseInt(sel.value);
}
