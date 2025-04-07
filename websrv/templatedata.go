package websrv

import (
	"net/http"
)

type requestArgs map[string]any
type errorMap map[string]any

type TemplateData struct {
	// The kind of page
	PageKind string

	// The Page title
	PageTitle string

	// The request arguments (e.g. query parameters)
	RequestArgs requestArgs

	// User information
	User *UserData

	// The General data to render the page
	Data any

	// ComponentData --> Additional named data elements
	ComponentData map[string]any

	// Generic error
	Error string

	// A map of specific errors
	//	["name"] --> Contains an error for a specific field
	Errors errorMap

	// A flash message
	Flash any
}

func NewTemplateData(r *http.Request, data ...any) *TemplateData {
	d := &TemplateData{
		PageKind:      "App",
		PageTitle:     "Page",
		RequestArgs:   make(requestArgs),
		ComponentData: make(map[string]any),
		Errors:        make(errorMap),
	}

	for k, v := range r.URL.Query() {
		d.RequestArgs[k] = v
	}

	if len(data) > 0 {
		d.SetData(data...)
	} else {
		d.SetData(map[string]any{})
	}
	return d
}

func (d *TemplateData) SetPageKind(kind string) {
	d.PageKind = kind
}

func (d *TemplateData) SetUser(data *UserData) {
	d.User = data
}

func (d *TemplateData) SetData(data ...any) {
	if len(data) == 0 {
		return
	}

	if len(data) == 1 {
		d.Data = data[0]
		return
	}

	var arr []any
	arr = append(arr, data...)
	/*for _, d := range data {
		arr = append(arr, d)
	}*/
	d.Data = arr
}

func (d *TemplateData) SetComponentData(name string, data any) {
	d.ComponentData[name] = data
}

func (d *TemplateData) SetPageTitle(title string) {
	d.PageTitle = title
}

func (d *TemplateData) SetError(err error) {
	d.Error = err.Error()
}

func (d *TemplateData) SetErrorString(errorString string) {
	d.Error = errorString
}

func (d *TemplateData) SetErrors(errs map[string]error) {
	for k, v := range errs {
		d.Errors[k] = v.Error()
	}
}

func (d *TemplateData) SetErrorStrings(errs map[string]string) {
	for k, v := range errs {
		d.Errors[k] = v
	}
}

func (d *TemplateData) SetFlashCookie(flash any) {
	d.Flash = flash
}

func (d *TemplateData) SetFlashFromCookie(
	w http.ResponseWriter,
	r *http.Request,
	name string,
) {
	var trigger string
	d.Flash, trigger, _ = GetStringFlashCookie(w, r, name)
	if trigger != "" {
		w.Header().Set("HX-Trigger-After-Swap", trigger)
	}
}

func (d *TemplateData) SetFlash(
	w http.ResponseWriter,
	flash any,
	trigger ...string,
) {
	d.Flash = flash
	if len(trigger) > 0 {
		w.Header().Set("HX-Trigger-After-Swap", trigger[0])
	}
}

type UserData struct {
	Email     string
	FirstName string
	LastName  string
	IsAdmin   bool
}

func NewUserDataFromClaims(r *http.Request) *UserData {
	claims := GetClaimsFromContext(r)
	if claims == nil {
		return nil
	}
	return &UserData{
		Email:   claims.GetUser(),
		IsAdmin: claims.IsAdministrator(),
	}
}
