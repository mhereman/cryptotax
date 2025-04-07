package assets

import (
	"bytes"
	"html/template"
	"reflect"

	"github.com/mhereman/cryptotax/backend"
)

func FuncMap() template.FuncMap {
	return template.FuncMap{
		"errorList": ErrorList,
		"truncate":  Truncate,
	}
}

func ErrorList(d any) template.HTML {
	val := reflect.ValueOf(d)
	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	errorField := val.FieldByName("Error")
	errorsField := val.FieldByName("Errors")

	var errorStr string
	if errorField.IsValid() && errorField.Kind() == reflect.String {
		errorStr = errorField.String()
	}

	var errorsMap map[string]any
	if errorsField.IsValid() && errorsField.Kind() == reflect.Map {
		errorsMap = make(map[string]any)
		for _, key := range errorsField.MapKeys() {
			if key.Kind() == reflect.String {
				val := errorsField.MapIndex(key)
				if val.Kind() == reflect.String {
					errorsMap[key.String()] = val.Interface()
				}
			}
		}
	}

	hasError := errorStr != ""
	hasErrors := len(errorsMap) > 0

	if !hasError && !hasErrors {
		return template.HTML("")
	}

	cnt := 0
	if hasError {
		cnt = 1
	}
	cnt += len(errorsMap)

	var buff bytes.Buffer
	var tmplStr string
	if cnt > 1 {
		tmplStr = `<ul>{{ if ne .Error "" }}<li>{{ .Error }}</li>{{ end }}{{ range $e := .Errors }}<li>{{ $e }}</li>{{ end }}</ul>`
	} else {
		tmplStr = `{{ if ne .Error "" }}{{ .Error }}{{ end }}{{ range $e := .Errors }}{{ $e }}{{ end }}`
	}
	tmpl := template.Must(template.New("").Parse(tmplStr))
	if err := tmpl.Execute(&buff, &d); err != nil {
		return template.HTML(err.Error())
	}
	return template.HTML(buff.String())
}

func Truncate(s string, maxLength int, addElipses bool) template.HTML {
	return template.HTML(backend.TruncateString(s, maxLength, addElipses))
}
