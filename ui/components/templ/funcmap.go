package templ

import "html/template"

type tmplData map[string]any

var funcmap = template.FuncMap{}

func Merge(target template.FuncMap) {
	for k, v := range funcmap {
		target[k] = v
	}
}
