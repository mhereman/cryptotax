function NumberInputUpdatePrecision(id, precision) {
    const varName = 'mdc'+id+'InputPrecision';
    window[varName] = precision;
    document.getElementById(id+'Input').value="0";
}