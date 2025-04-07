function setInnerHTML(elem, html) {
    elem.innerHTML = html;

    Array.from(elem.querySelectorAll('script')).forEach(oldScriptEl => {
        const newScriptEl = document.createElement('script');

        Array.from(oldScriptEl.attributes).forEach(attr => {
            newScriptEl.setAttribute(attr.name, attr.value);
        });

        const scriptText = document.createTextNode(oldScriptEl.textContent);
        newScriptEl.appendChild(scriptText);

        oldScriptEl.parentNode.replaceChild(newScriptEl, oldScriptEl);
    });
}

function onScriptLoaded(src, callback) {
    const script = document.querySelector('script[src="'+src+'"]');
    if (script && script.readyState === 'complete') {
        callback();
    } else {
        script.addEventListener('load', callback);
    }
}