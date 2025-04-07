package templ

import "html/template"

var componentButtonOptKeys []string
var componentIconButtonOptKeys []string

func init() {
	componentButtonOptKeys = []string{"Style", "Variant", "Icon", "IconPosition"}
	componentIconButtonOptKeys = []string{"Variant"}

	// Button
	// $btn := Button id label onclick [style variant icon iconPosition]
	funcmap["Button"] = componentButton

	// IconButton
	// $btn := IconButton id icon onclick [variant]
	funcmap["IconButton"] = componentIconButton
}

func componentButton(
	id string, label string, onclick string, opts ...string,
) tmplData {
	data := tmplData{
		"Id":      id,
		"Label":   label,
		"OnClick": template.JS(onclick),
	}
	for idx, opt := range opts {
		if idx >= len(componentButtonOptKeys) {
			break
		}
		data[componentButtonOptKeys[idx]] = opt
	}
	return data
}

func componentIconButton(
	id string, icon string, onclick string, opts ...string,
) tmplData {
	data := tmplData{
		"Id":      id,
		"Icon":    icon,
		"OnClick": template.JS(onclick),
	}
	for idx, opt := range opts {
		if idx >= len(componentIconButtonOptKeys) {
			break
		}
		data[componentIconButtonOptKeys[idx]] = opt
	}
	return data
}
