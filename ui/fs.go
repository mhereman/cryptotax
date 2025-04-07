package ui

import (
	"embed"
	"html/template"

	"github.com/Masterminds/sprig/v3"
)

//go:embed templates/*
var TemplateFS embed.FS

//go:embed components/templates/*
var ComponentTemplateFS embed.FS

//go:embed static/*
var StaticFS embed.FS

var Templates *template.Template

func LoadFiles() {
	Templates = template.Must(
		template.New("").
			Funcs(funcmap).
			Funcs(sprig.FuncMap()).
			ParseFS(TemplateFS, "templates/*.html"))
	Templates = template.Must(Templates.ParseFS(ComponentTemplateFS, "components/templates/*.html"))
}
