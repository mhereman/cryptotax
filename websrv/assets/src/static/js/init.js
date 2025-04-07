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
