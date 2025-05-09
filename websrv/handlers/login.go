package handlers

import (
	"html/template"
	"net/http"

	"github.com/mhereman/cryptotax/backend"
	"github.com/mhereman/cryptotax/backend/cryptodb"
	"github.com/mhereman/cryptotax/backend/validators"
	"github.com/mhereman/cryptotax/websrv"
	"github.com/mhereman/cryptotax/websrv/assets"
	"github.com/mhereman/cryptotax/websrv/errmsg"
)

func init() {
	http.HandleFunc("POST /login", login)
	http.HandleFunc("GET /logout", logout)
	http.HandleFunc("POST /login/.validate", loginValidate)
}

func login(w http.ResponseWriter, r *http.Request) {
	var user *cryptodb.User
	var err error

	email := r.FormValue("email")
	pw := r.FormValue("password")

	loginFailure := (email == "" || pw == "")
	if !loginFailure {
		if user, err = cryptodb.GetUser(email); err != nil {
			loginFailure = true
		}
	}

	if !loginFailure {
		loginFailure = !backend.VerifyPassword(pw, user.PasswordHash)
	}

	if loginFailure {
		data := websrv.NewTemplateData(r)
		data.SetPageKind("Login")
		data.SetPageTitle("CyproTax - Login")
		data.SetErrorString(errmsg.MsgInvalidLoginCredentials)
		data.SetData(map[string]any{
			"Email": email,
		})
		websrv.RenderHtmlPage(w, r, "index.html", data)
		return
	}

	websrv.CreateJWT(w, email, user.IsAdmin)
	websrv.Redirect(w, r, "/", http.StatusSeeOther)
}

func logout(w http.ResponseWriter, r *http.Request) {
	websrv.RemoveJWT(w)
	websrv.Redirect(w, r, "/", http.StatusSeeOther)
}

func loginValidate(w http.ResponseWriter, r *http.Request) {
	errors := make(map[string]string)
	fld := websrv.QueryArg(r, "f")

	if r.FormValue("email") != "" {
		if err := validators.ValidateEmail(r.FormValue("email")); err != nil {
			errors["email"] = errmsg.MsgInvalidEmail
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

		d := map[string]any{
			"Errors": errors,
		}
		websrv.RenderHtmlString(w, r, assets.ErrorList(d))
	}
	websrv.RenderHtmlString(w, r, "")
}
