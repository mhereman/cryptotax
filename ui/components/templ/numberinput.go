package templ

import (
	"github.com/shopspring/decimal"
)

var componentNumberInputOptKeys []string

func init() {
	componentNumberInputOptKeys = []string{"Style"}

	// NumberInput
	// $inp := NumberInput id label value precision [style]
	funcmap["NumberInput"] = componentNumberInput
	// $_ := NumberInputSetPrefix $inp prefix
	funcmap["NumberInputSetPrefix"] = componentNumberInputSetPrefix
	// $_ := NumberInputSetPostfix $inp postfix
	funcmap["NumberInputSetSuffix"] = componentNumberInputSetSuffix
	// $_ := NumberInputSetMin $inp min
	funcmap["NumberInputSetMin"] = componentNumberInputSetMin
	// $_ := NumberInputSetMax 4inp max
	funcmap["NumberInputSetMax"] = componentNumberInputSetMax
}

func componentNumberInput(
	id string, label string, value string, precision int, opts ...string,
) tmplData {
	d := decimal.NewFromInt(1)
	d = d.Div(decimal.NewFromInt(10).Pow(decimal.NewFromInt(int64(precision))))

	data := tmplData{
		"Id":        id,
		"Label":     label,
		"Value":     value,
		"Precision": precision,
	}
	for idx, opt := range opts {
		if idx >= len(componentNumberInputOptKeys) {
			break
		}
		data[componentNumberInputOptKeys[idx]] = opt
	}
	return data
}

func componentNumberInputSetPrefix(
	inp tmplData, prefix string,
) tmplData {
	inp["Prefix"] = prefix
	return inp
}

func componentNumberInputSetSuffix(
	inp tmplData, suffix string,
) tmplData {
	inp["Suffix"] = suffix
	return inp
}

func componentNumberInputSetMin(
	inp tmplData, min string,
) tmplData {
	inp["Min"] = min
	return inp
}

func componentNumberInputSetMax(
	inp tmplData, max string,
) tmplData {
	inp["Max"] = max
	return inp
}
