package templ

import (
	"fmt"
	"html/template"
)

func init() {

	// Select
	// $sel := Select id label selectedValue onChange
	funcmap["Select"] = componentSelect
	// $_ := SelectAddOption $sel Label Value
	funcmap["SelectAddOption"] = componentSelectAddOption
	// $_ := SelectOptions $sel [label1 value1 label2 value2 ...]
	funcmap["SelectOptions"] = componentSelectOptions
}

func componentSelect(
	id string, label string, selectedvalue any, onchange string,
) tmplData {
	return tmplData{
		"Id":            id,
		"Label":         label,
		"SelectedValue": selectedvalue,
		"OnChange":      template.JS(onchange),
	}
}

func componentSelectAddOption(
	sel tmplData, label string, value any,
) tmplData {
	var arr []map[string]any

	if data, ok := sel["Options"]; ok {
		arr = data.([]map[string]any)
	} else {
		arr = make([]map[string]any, 0)
	}

	item := map[string]any{
		"Label": label,
		"Value": value,
	}
	arr = append(arr, item)
	sel["Options"] = arr
	return sel
}

func componentSelectOptions(
	sel tmplData, options ...any,
) tmplData {
	arr := []map[string]any{}
	lbl := ""

	for _, val := range options {
		if lbl == "" {
			lbl = fmt.Sprintf("%v", val)
		} else {
			item := map[string]any{
				"Label": lbl,
				"Value": val,
			}
			arr = append(arr, item)
			lbl = ""
		}
	}
	sel["Options"] = arr
	return sel
}
