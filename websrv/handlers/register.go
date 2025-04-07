package handlers

import (
	"html/template"
	"net/http"

	"github.com/mhereman/cryptotax/backend"
	"github.com/mhereman/cryptotax/backend/cryptodb"
	"github.com/mhereman/cryptotax/backend/validators"
	"github.com/mhereman/cryptotax/websrv"
	"github.com/mhereman/cryptotax/websrv/assets"
	"github.com/mhereman/cryptotax/websrv/middlewares"
)

func init() {
	http.HandleFunc("POST /register/admin", middlewares.NoUserPresent(registerAdmin))
	http.HandleFunc("POST /register/.validate", registerValidate)
}

func registerAdmin(w http.ResponseWriter, r *http.Request) {
	errors := make(map[string]string)
	email := r.FormValue("email")
	pw1 := r.FormValue("password")
	pw2 := r.FormValue("passwordConfirm")

	if err := validators.ValidateEmail(email); err != nil {
		errors["email"] = MsgInvalidEmail
	}
	if err := validators.ValidatePasswordStrength(pw1); err != nil {
		errors["password"] = MsgWeakPassword
	} else if err := validators.ValidatePasswordsMatch(pw1, pw2); err != nil {
		errors["password"] = MsgPasswordMismatch
	}

	data := websrv.NewTemplateData(r)
	if len(errors) > 0 {
		data.SetPageKind("Register")
		data.SetPageTitle("CryptoTax - Register")
		data.SetErrorStrings(errors)
		data.SetData(map[string]any{
			"Email": email,
		})
		websrv.RenderHtmlPage(w, r, "index.html", data)
		return
	}

	// Hash password
	hash, err := backend.HashPassword(pw1)
	if err != nil {
		errors["password"] = err.Error()
	}
	if len(errors) > 0 {
		data.SetPageKind("Register")
		data.SetPageTitle("CryptoTax - Register")
		data.SetErrorStrings(errors)
		data.SetData(map[string]any{
			"Email": email,
		})
		websrv.RenderHtmlPage(w, r, "index.html", data)
		return
	}

	// Add to database
	err = cryptodb.CreateUser(email, hash, true)
	if err != nil {
		websrv.InternalServerError(w, r, err)
		return
	}

	// Generate jwt token and redirect
	websrv.CreateJWT(w, email, true)
	websrv.Redirect(w, r, "/", http.StatusSeeOther)
}

func registerValidate(w http.ResponseWriter, r *http.Request) {
	errors := make(map[string]string)
	fld := websrv.QueryArg(r, "f")

	if r.FormValue("email") != "" {
		if err := validators.ValidateEmail(r.FormValue("email")); err != nil {
			errors["email"] = MsgInvalidEmail
		}
	}

	if r.FormValue("password") != "" {
		if err := validators.ValidatePasswordStrength(r.FormValue("password")); err != nil {
			errors["password"] = MsgWeakPassword
		}
	}

	if r.FormValue("passwordConfirm") != "" {
		if err := validators.ValidatePasswordsMatch(r.FormValue("password"), r.FormValue("passwordConfirm")); err != nil {
			errors["passwordConfirm"] = MsgPasswordMismatch
		}
	}

	if len(errors) > 0 {
		if fld != "" {
			err, ok := errors[fld]
			if !ok {
				websrv.RenderHtmlString(w, r, "")
				return
			}
			websrv.RenderHtmlString(w, r, template.HTML(err))
			return
		}

		// Otherwise return first error
		d := map[string]any{
			"Errors": errors,
		}
		websrv.RenderHtmlString(w, r, assets.ErrorList(d))
	}
	websrv.RenderHtmlString(w, r, "")
}
