package assets

import (
	"fmt"
	"html/template"
	"io"

	"github.com/Masterminds/sprig/v3"
)

type PageTemplate struct {
	*template.Template
}

func (p PageTemplate) Execute(wr io.Writer, data any) error {
	return p.Template.ExecuteTemplate(wr, "page", data)
}

type PageSet map[string]*PageTemplate

func (p PageSet) NewPage(name string, patterns ...string) {
	templates := make([]string, 0, len(patterns))
	for _, p := range patterns {
		templates = append(templates, fmt.Sprintf("templates/%s", p))
	}
	p[name] = &PageTemplate{
		template.Must(
			template.New("").
				Funcs(sprig.FuncMap()).
				Funcs(FuncMap()).
				ParseFS(TemplateFS, templates...)),
	}
}

func (p PageSet) ExecutePage(wr io.Writer, pageName string, data any) error {
	t, ok := p[pageName]
	if !ok {
		return fmt.Errorf("page not defined: %s", pageName)
	}
	return t.Execute(wr, data)
}
