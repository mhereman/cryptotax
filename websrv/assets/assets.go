package assets

import (
	"embed"
	"html/template"

	"github.com/Masterminds/sprig/v3"
)

//go:embed all:static
var StaticFS embed.FS

//go:embed all:templates
var TemplateFS embed.FS

var Templates *template.Template
var Pages PageSet

func init() {
	Templates = template.Must(
		template.New("").
			Funcs(sprig.FuncMap()).
			Funcs(FuncMap()).
			ParseFS(TemplateFS, "templates/**/*.html"))

	Pages = make(PageSet)
	Pages.NewPage("index.html", "page.html",
		"index.html", "login.html", "register.html",
		"svg.html", "sidebar.html", "main.html",
		"pages/home.html",
		"pages/settings.html",
		"components/theme-chooser.html")
}
