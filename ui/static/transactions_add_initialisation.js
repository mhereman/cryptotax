function setAsset(selectElem) {
    let asset = selectElem.value;
    NumberInputUpdatePrecision('amountInput', getAssetPrecision(asset));
}

function setValuationType(selectElem) {

}