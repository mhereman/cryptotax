package ui

import (
	"bytes"
	"html/template"
	"reflect"
	"strings"
	tt "text/template"

	"github.com/Masterminds/sprig/v3"
	"github.com/mhereman/cryptotax/ui/components/templ"
)

var funcmap = template.FuncMap{
	"sizei":      func(s []int) int { return len(s) },
	"firsti":     func(s []int) int { return s[0] },
	"lasti":      func(s []int) int { return s[len(s)-1] },
	"avail":      avail,
	"trimQuotes": func(s string) string { return strings.Trim(s, "\"") },
	"asJS":       func(s string) template.JS { return template.JS(s) },
	"eval":       eval,
	"evalJS":     func(s string, d any) template.JS { return template.JS(eval(s, d)) },
}

func init() {
	templ.Merge(funcmap)
}

// avail checks if the template data has the requested fiedl
func avail(name string, data any) bool {
	v := reflect.ValueOf(data)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}
	if v.Kind() != reflect.Struct {
		return false
	}
	return v.FieldByName(name).IsValid()
}

func eval(s string, data any) string {
	tmpl := tt.Must(tt.New("").Funcs(sprig.FuncMap()).Parse(s))
	var tpl bytes.Buffer
	if err := tmpl.Execute(&tpl, data); err != nil {
		panic(err)
	}
	return tpl.String()
}
