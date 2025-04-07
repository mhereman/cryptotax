package handlers

import (
	"errors"
	"net/http"

	"github.com/mhereman/cryptotax/backend/cryptodb"
	"github.com/mhereman/cryptotax/websrv"
	"github.com/mhereman/cryptotax/websrv/middlewares"
)

func init() {
	middlewares.InitializeHandlerFunc = initializePage
	middlewares.LoginHandlerFunc = loginPage

	http.HandleFunc("GET /home", middlewares.Auth(homePage))
}

type MainPage string

const (
	MainPageHome     = "Home"
	MainPageSettings = "Settings"
)

type MainPageData struct {
	Type  MainPage
	Title string
}

func NewMainPageData(typ MainPage, title string) *MainPageData {
	return &MainPageData{
		Type:  typ,
		Title: title,
	}
}

func initializePage(w http.ResponseWriter, r *http.Request) {
	data := websrv.NewTemplateData(r)
	data.SetPageKind("Register")
	data.SetPageTitle("CryptoTax - Register")
	websrv.RenderHtmlPage(w, r, "index.html", data)
}

func loginPage(w http.ResponseWriter, r *http.Request) {
	data := websrv.NewTemplateData(r)
	data.SetPageKind("Login")
	data.SetPageTitle("CryptoTax - Login")
	websrv.RenderHtmlPage(w, r, "index.html", data)
}

type HomePageData struct {
	*MainPageData
}

func NewHomePageData() *HomePageData {
	return &HomePageData{
		MainPageData: NewMainPageData(MainPageHome, "Home"),
	}
}

func homePage(w http.ResponseWriter, r *http.Request) {
	userData := getUserData(r)
	if userData == nil {
		websrv.InternalServerError(w, r, errors.New(MsgUserNotFound))
		return
	}

	pageData := NewHomePageData()

	data := websrv.NewTemplateData(r)
	data.SetPageTitle("CryptoTax - Home")
	data.SetUser(userData)
	data.SetData(pageData)
	websrv.RenderHtmlPage(w, r, "index.html", data)
}

func getUserData(r *http.Request) *websrv.UserData {
	userData := websrv.NewUserDataFromClaims(r)
	if userData != nil {
		if userDetails, err := cryptodb.GetUserDetails(userData.Email); err == nil {
			userData.FirstName = userDetails.FirstName
			userData.LastName = userDetails.LastName
		}
	}
	return userData
}
