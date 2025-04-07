function formInputErrorCheck(inputId) {
    const input = document.getElementById(inputId);
    const form = input.closest('form');
    const helpBlock = form.querySelector('.help-block');
    const submitButton = form.querySelector('.submit-button');

    input.classList.remove('is-valid', 'is-invalid');
    helpBlock.classList.remove('form-error-message');

    if (helpBlock.innerText === '') {
        if (input.value !== '') {
            input.classList.add('is-valid');
            helpBlock.innerHTML = '';
        }
    } else {
        input.classList.add('is-invalid');
        helpBlock.classList.add('form-error-message');
    }

    if (typeof submitButton !== 'undefined') {
        setFormSubmitEnabled(submitButton);
    }
}

function setFormSubmitEnabled(button) {
    if (typeof button === 'undefined') {
        return;
    }

    const form = button.closest('form');
    const inputs = form.querySelectorAll('input');

    button.setAttribute('disabled', 'disabled');
    inputs.forEach((input) => {
        if (input.classList.contains('is-invalid')) return;
    });

    button.removeAttribute('disabled');
}

function onBeforeFormSubmit(event, form) {
    if (event.target === event.currentTarget) {
        const button = form.querySelector('.submit-button');
        setFormSubmitBusy(button);
    }
    return true;
}

function setFormSubmitBusy(button) {
    if (typeof button === 'undefined') {
        return;
    }

    const spinner = button.querySelector('.spinner-border');

    button.setAttribute('disabled', 'disabled');
    spinner.classList.remove('visually-hidden');
}
