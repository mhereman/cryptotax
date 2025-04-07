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