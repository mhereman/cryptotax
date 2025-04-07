package ui

import (
	"net/http"

	"github.com/mhereman/cryptotax/ui/handlers"
)

func SetupPages() {
	registerIndex()
}

type indexData struct {
	Title   string
	AppName string
	Layout  *siteLayout
}

type siteLayout struct {
	Categories []*category
}

func (sl *siteLayout) AddPage(cat string, title string, label string, link string) {
	var c *category

	for _, ct := range sl.Categories {
		if ct.Label == cat {
			c = ct
			break
		}
	}

	if c == nil {
		sl.Categories = append(sl.Categories, &category{Label: cat, Pages: []*page{{Title: title, Label: label, Link: link}}})
		return
	}

	c.Pages = append(c.Pages, &page{Title: title, Label: label, Link: link})
}

type category struct {
	Label string
	Pages []*page
}

type page struct {
	Title string
	Label string
	Link  string
}

func registerPages() *siteLayout {
	sl := &siteLayout{}

	http.HandleFunc("/home/dashboard", homeDashboardHandler)
	sl.AddPage("Home", "Dashboard", "Dashboard", "/home/dashboard")

	http.HandleFunc("/home/about", homeAbountHandler)
	sl.AddPage("Home", "About CryptoTax", "About", "/home/about")

	http.HandleFunc("/transactions/overview", handlers.TransactionsOverview(Templates))
	sl.AddPage("Transactions", "Transactions", "Overview", "/transactions/overview")

	http.HandleFunc("/transactions/add", handlers.TransactionsAdd(Templates))
	http.HandleFunc("/transactions/add/initialisation", handlers.TransactionsAddInitialisation(Templates))
	http.HandleFunc("/transactions/add/trade", handlers.TransactionsAddTrade(Templates))
	http.HandleFunc("/transactions/add/txfee", handlers.TransactionsAddTxFee(Templates))
	sl.AddPage("Transactions", "Add Transaction", "Add Transaction", "/transactions/add")

	return sl
}

func registerIndex() {
	idxData := &indexData{
		Title:   "CryptoTax",
		AppName: "CryptoTax",
	}
	idxData.Layout = registerPages()
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if err := Templates.ExecuteTemplate(w, "index.html", idxData); err != nil {
			panic(err)
		}
	})
}

func homeDashboardHandler(w http.ResponseWriter, r *http.Request) {
	if err := Templates.ExecuteTemplate(w, "home_dashboard.html", nil); err != nil {
		panic(err)
	}
}

func homeAbountHandler(w http.ResponseWriter, r *http.Request) {
	if err := Templates.ExecuteTemplate(w, "home_about.html", nil); err != nil {
		panic(err)
	}
}

func transactionsOverviewHandler(w http.ResponseWriter, r *http.Request) {
	if err := Templates.ExecuteTemplate(w, "transactions_overview.html", nil); err != nil {
		panic(err)
	}
}
