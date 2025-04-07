const Toast = Swal.mixin({
    toast: true,
    position: "top-end",
    showConfirmButton: false,
    timer: 3000,
    timerProgressBar: true,
    didOpen: function(toast) {
        toast.onmouseover = Swal.stopTimer;
        toast.onmouseleave = Swal.resumeTimer;
    }
});

async function showFlashMessage(message) {
   await Toast.fire({
        icon: "success",
        title: message
    });
}
/****************************************************************************
 * The following variables are global application state variables
 * and are required for the functioning of the page.
 ****************************************************************************/

// The flash message to show
// Showing of the flash message will happen via the event app:flash
// If at that moment, the variable is assigned, the message will be shown.
// see eventListener app:flash
var flashMessage='';


document.addEventListener("htmx:confirm", function(e) {
    if (!e.detail.elt.hasAttribute('hx-confirm')) return;
    e.preventDefault();

    Swal.fire({
        title: "Proceed?",
        text: e.detail.question,
        showCancelButton: true,
        allowOutsideClick: false,
        reverseButtons: true,
    }).then(function(result){
        if (result.isConfirmed) {
            e.detail.issueRequest(true);
        }
    });
});

document.addEventListener("app:flash", function(e) {
    e.preventDefault();
    if (flashMessage !== '') {
        showFlashMessage(flashMessage);
    }
})

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

