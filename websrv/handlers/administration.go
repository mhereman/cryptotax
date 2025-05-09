package handlers

import (
	"net/http"

	"github.com/mhereman/cryptotax/websrv"
	"github.com/mhereman/cryptotax/websrv/middlewares"
)

func init() {
	http.HandleFunc("GET /administration", middlewares.Auth(middlewares.IsAdmin(administrationPage)))
}

type AdministrationPageData struct {
	*MainPageData
}

func NewAdministrationPageData() *AdministrationPageData {
	return &AdministrationPageData{
		MainPageData: NewMainPageData(MainPageAdministration, "Administration"),
	}
}

func administrationPage(w http.ResponseWriter, r *http.Request) {
	userData := enrichUserData(middlewares.GetUserFromContext(r))
	pageData := NewAdministrationPageData()

	data := websrv.NewTemplateData(r)
	data.SetPageTitle("CryptoTax - Administration")
	data.SetUser(userData)
	data.SetData(pageData)
	websrv.RenderHtmlPage(w, r, "index.html", data)
}
