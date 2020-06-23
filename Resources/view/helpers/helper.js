function anyDescendantHasActiveFocus(ancestor) {
    let item = appWindow.activeFocusItem;
    while (item) {
        if (item === ancestor)
            return true;
        item = item.parent;
    }
    return false;
}

function toCurrency(moneyStr) {
    return parseFloat(moneyStr).toFixed(2).replace('.', ',').replace(/(\d)(?=(\d{3})+\,)/g, '$1.') + "₺";
}

function moneyStr2float() {
    return moneyStr.replace(/[₺|.]/g, '').replace(',', '.');
}
