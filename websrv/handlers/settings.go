package handlers

import (
	"errors"
	"net/http"

	"github.com/mhereman/cryptotax/websrv"
	"github.com/mhereman/cryptotax/websrv/middlewares"
)

func init() {
	http.HandleFunc("GET /settings", middlewares.Auth(settingsPage))
}

type SettingsPageData struct {
	*MainPageData
}

func NewSettingsPageData() *SettingsPageData {
	return &SettingsPageData{
		MainPageData: NewMainPageData(MainPageSettings, "Settings"),
	}
}

func settingsPage(w http.ResponseWriter, r *http.Request) {
	userData := getUserData(r)
	if userData == nil {
		websrv.InternalServerError(w, r, errors.New(MsgUserNotFound))
		return
	}

	pageData := NewSettingsPageData()

	data := websrv.NewTemplateData(r)
	data.SetPageTitle("CryptoTax - Settings")
	data.SetUser(userData)
	data.SetData(pageData)
	websrv.RenderHtmlPage(w, r, "index.html", data)
}
