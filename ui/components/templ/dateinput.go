package templ

var componentDateInputOptKeys []string

func init() {
	componentDateInputOptKeys = []string{"Style"}

	// DateInput
	// $inp := DateInput id label [style]
	funcmap["DateInput"] = componentDateInput
}

func componentDateInput(
	id string, label string, opts ...string,
) tmplData {
	data := tmplData{
		"Id":    id,
		"Label": label,
	}
	for idx, opt := range opts {
		if idx >= len(componentDateInputOptKeys) {
			break
		}
		data[componentDateInputOptKeys[idx]] = opt
	}
	return data
}
